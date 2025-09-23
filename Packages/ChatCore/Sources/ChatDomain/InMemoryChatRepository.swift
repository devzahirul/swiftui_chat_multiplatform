import Foundation

public actor InMemoryChatRepository: ChatRepository {
    private var chats: [String: Chat] = [:]
    private var messages: [String: [Message]] = [:]
    private var continuations: [String: [AsyncThrowingStream<[Message], Error>.Continuation]] = [:]

    public init() {}

    public func createChat(members: [ChatUser]) async throws -> Chat {
        let chat = Chat(memberIds: members.map { $0.id })
        chats[chat.id] = chat
        messages[chat.id] = []
        return chat
    }

    public func messagesStream(chatId: String) -> AsyncThrowingStream<[Message], Error> {
        AsyncThrowingStream { continuation in
            continuations[chatId, default: []].append(continuation)
            continuation.onTermination = { [weak self] _ in
                guard let self else { return }
                self.continuations[chatId]?.removeAll { $0 === continuation }
            }
            continuation.yield(messages[chatId] ?? [])
        }
    }

    public func send(message: Message) async throws {
        guard chats[message.chatId] != nil else { throw ChatError.chatNotFound }
        messages[message.chatId, default: []].append(message)
        let current = messages[message.chatId] ?? []
        continuations[message.chatId]?.forEach { $0.yield(current) }
    }
}
