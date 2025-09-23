import Foundation

public final class InMemoryChatRepository: ChatRepository {
    private struct Listener {
        let id: UUID
        let continuation: AsyncThrowingStream<[Message], Error>.Continuation
    }

    private var chats: [String: Chat] = [:]
    private var messages: [String: [Message]] = [:]
    private var listeners: [String: [Listener]] = [:]
    private let queue = DispatchQueue(label: "InMemoryChatRepository.queue", attributes: .concurrent)
    private let writeQueue = DispatchQueue(label: "InMemoryChatRepository.write")

    public init() {}

    public func createChat(members: [ChatUser]) async throws -> Chat {
        let chat = Chat(memberIds: members.map { $0.id })
        writeQueue.sync {
            chats[chat.id] = chat
            messages[chat.id] = []
        }
        return chat
    }

    public func messagesStream(chatId: String) -> AsyncThrowingStream<[Message], Error> {
        let id = UUID()
        return AsyncThrowingStream { continuation in
            // Register listener and emit current snapshot
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
        var existingChat: Chat?
        queue.sync { existingChat = chats[message.chatId] }
        guard existingChat != nil else { throw ChatError.chatNotFound }

        // Mutate messages, then broadcast to listeners
        var snapshot: [Message] = []
        writeQueue.sync {
            messages[message.chatId, default: []].append(message)
            snapshot = messages[message.chatId] ?? []
        }
        // Snapshot listeners to avoid holding the write lock during yields
        var toNotify: [Listener] = []
        queue.sync { toNotify = listeners[message.chatId] ?? [] }
        toNotify.forEach { $0.continuation.yield(snapshot) }
    }
}
