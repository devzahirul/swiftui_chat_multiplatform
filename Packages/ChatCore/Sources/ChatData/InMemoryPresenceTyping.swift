import Foundation
import ChatDomain

// Simple in-memory PresenceRepository for demos/tests
public final class InMemoryPresenceRepository: PresenceRepository {
    private actor Storage {
        var continuations: [String: Set<ObjectIdentifier>] = [:]
        var sinks: [ObjectIdentifier: AsyncStream<Presence>.Continuation] = [:]
    }
    private let storage = Storage()

    public init() {}

    public func presenceStream(userId: String) -> AsyncThrowingStream<Presence, Error> {
        let stream = AsyncThrowingStream<Presence, Error> { continuation in
            let id = ObjectIdentifier(continuation as AnyObject)
            Task { await storage.sinks[id] = continuation }
            Task { await storage.continuations[userId, default: []].insert(id) }
            continuation.onTermination = { _ in
                Task {
                    await storage.sinks.removeValue(forKey: id)
                    await storage.continuations[userId]?.remove(id)
                }
            }
        }
        return stream
    }

    public func setPresence(userId: String, isOnline: Bool) async throws {
        let presence = Presence(userId: userId, isOnline: isOnline)
        await broadcast(userId: userId, presence: presence)
    }

    private func broadcast(userId: String, presence: Presence) async {
        await storage.continuations[userId]?.forEach { oid in
            if let cont = storage.sinks[oid] {
                cont.yield(presence)
            }
        }
    }
}

// Simple in-memory TypingRepository for demos/tests
public final class InMemoryTypingRepository: TypingRepository {
    private actor Storage {
        var conts: [String: Set<ObjectIdentifier>] = [:]
        var sinks: [ObjectIdentifier: AsyncStream<TypingIndicator>.Continuation] = [:]
    }
    private let storage = Storage()

    public init() {}

    public func typingStream(chatId: String) -> AsyncThrowingStream<TypingIndicator, Error> {
        let stream = AsyncThrowingStream<TypingIndicator, Error> { continuation in
            let id = ObjectIdentifier(continuation as AnyObject)
            Task { await storage.sinks[id] = continuation }
            Task { await storage.conts[chatId, default: []].insert(id) }
            continuation.onTermination = { _ in
                Task {
                    await storage.sinks.removeValue(forKey: id)
                    await storage.conts[chatId]?.remove(id)
                }
            }
        }
        return stream
    }

    public func setTyping(chatId: String, userId: String, isTyping: Bool) async throws {
        let indicator = TypingIndicator(chatId: chatId, userId: userId, isTyping: isTyping)
        await broadcast(chatId: chatId, indicator: indicator)
    }

    private func broadcast(chatId: String, indicator: TypingIndicator) async {
        await storage.conts[chatId]?.forEach { oid in
            if let cont = storage.sinks[oid] {
                cont.yield(indicator)
            }
        }
    }
}

