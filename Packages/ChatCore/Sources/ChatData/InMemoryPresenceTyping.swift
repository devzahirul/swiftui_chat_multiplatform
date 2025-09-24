import Foundation
import ChatDomain

// Simple in-memory PresenceRepository for demos/tests
public final class InMemoryPresenceRepository: PresenceRepository {
    private actor Storage {
        var continuations: [String: Set<ObjectIdentifier>] = [:]
        var sinks: [ObjectIdentifier: AsyncThrowingStream<Presence, Error>.Continuation] = [:]

        func add(userId: String, id: ObjectIdentifier, continuation: AsyncThrowingStream<Presence, Error>.Continuation) {
            sinks[id] = continuation
            continuations[userId, default: []].insert(id)
        }

        func remove(userId: String, id: ObjectIdentifier) {
            sinks.removeValue(forKey: id)
            continuations[userId]?.remove(id)
        }

        func broadcast(userId: String, presence: Presence) {
            for oid in continuations[userId] ?? [] {
                sinks[oid]?.yield(presence)
            }
        }
    }
    private let storage = Storage()

    public init() {}

    public func presenceStream(userId: String) -> AsyncThrowingStream<Presence, Error> {
        AsyncThrowingStream<Presence, Error> { continuation in
            let id = ObjectIdentifier(continuation as AnyObject)
            Task { await self.storage.add(userId: userId, id: id, continuation: continuation) }
            continuation.onTermination = { _ in Task { await self.storage.remove(userId: userId, id: id) } }
        }
    }

    public func setPresence(userId: String, isOnline: Bool) async throws {
        let presence = Presence(userId: userId, isOnline: isOnline)
        await storage.broadcast(userId: userId, presence: presence)
    }
}

// Simple in-memory TypingRepository for demos/tests
public final class InMemoryTypingRepository: TypingRepository {
    private actor Storage {
        var conts: [String: Set<ObjectIdentifier>] = [:]
        var sinks: [ObjectIdentifier: AsyncThrowingStream<TypingIndicator, Error>.Continuation] = [:]

        func add(chatId: String, id: ObjectIdentifier, continuation: AsyncThrowingStream<TypingIndicator, Error>.Continuation) {
            sinks[id] = continuation
            conts[chatId, default: []].insert(id)
        }

        func remove(chatId: String, id: ObjectIdentifier) {
            sinks.removeValue(forKey: id)
            conts[chatId]?.remove(id)
        }

        func broadcast(chatId: String, indicator: TypingIndicator) {
            for oid in conts[chatId] ?? [] {
                sinks[oid]?.yield(indicator)
            }
        }
    }
    private let storage = Storage()

    public init() {}

    public func typingStream(chatId: String) -> AsyncThrowingStream<TypingIndicator, Error> {
        AsyncThrowingStream<TypingIndicator, Error> { continuation in
            let id = ObjectIdentifier(continuation as AnyObject)
            Task { await self.storage.add(chatId: chatId, id: id, continuation: continuation) }
            continuation.onTermination = { _ in Task { await self.storage.remove(chatId: chatId, id: id) } }
        }
    }

    public func setTyping(chatId: String, userId: String, isTyping: Bool) async throws {
        let indicator = TypingIndicator(chatId: chatId, userId: userId, isTyping: isTyping)
        await storage.broadcast(chatId: chatId, indicator: indicator)
    }
}
