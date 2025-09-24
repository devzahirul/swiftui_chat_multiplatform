import Foundation
import ChatDomain

public final class InMemoryChatDataSource: ChatDataSource {
    private struct Listener {
        let id: UUID
        let continuation: AsyncThrowingStream<[Message], Error>.Continuation
    }

    private var chats: [String: Chat] = [:]
    private var messages: [String: [Message]] = [:]
    private var listeners: [String: [Listener]] = [:]
    private let queue = DispatchQueue(label: "InMemoryChatDataSource.queue", attributes: .concurrent)
    private let writeQueue = DispatchQueue(label: "InMemoryChatDataSource.write")

    public init() {}

    public func createChat(members: [ChatUser]) async throws -> Chat {
        let chat = Chat(memberIds: members.map { $0.id })
        writeQueue.sync {
            chats[chat.id] = chat
            messages[chat.id] = []
        }
        return chat
    }

    public func getAllChats() async throws -> [Chat] {
        var list: [Chat] = []
        queue.sync { list = Array(chats.values) }
        return list.sorted(by: { $0.createdAt > $1.createdAt })
    }

    public func getLatestMessage(chatId: String) async throws -> Message? {
        var last: Message?
        queue.sync { last = messages[chatId]?.last }
        return last
    }

    public func messagesStream(chatId: String) -> AsyncThrowingStream<[Message], Error> {
        let id = UUID()
        return AsyncThrowingStream { continuation in
            writeQueue.async {
                var arr = self.listeners[chatId] ?? []
                arr.append(Listener(id: id, continuation: continuation))
                self.listeners[chatId] = arr
                let current = self.messages[chatId] ?? []
                continuation.yield(current)
            }

            continuation.onTermination = { [weak self] _ in
                guard let self else { return }
                self.writeQueue.async {
                    self.listeners[chatId]?.removeAll { $0.id == id }
                }
            }
        }
    }

    public func send(message: Message) async throws {
        var exists: Chat?
        queue.sync { exists = chats[message.chatId] }
        guard exists != nil else { throw ChatError.chatNotFound }

        var snapshot: [Message] = []
        writeQueue.sync {
            messages[message.chatId, default: []].append(message)
            snapshot = messages[message.chatId] ?? []
        }
        var toNotify: [Listener] = []
        queue.sync { toNotify = listeners[message.chatId] ?? [] }
        toNotify.forEach { $0.continuation.yield(snapshot) }
    }
}

