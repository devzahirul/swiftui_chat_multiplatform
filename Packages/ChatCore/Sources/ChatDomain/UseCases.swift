import Foundation

public struct ObserveMessagesUseCase {
    let repo: ChatRepository
    public init(repo: ChatRepository) { self.repo = repo }
    public func callAsFunction(chatId: String) -> AsyncThrowingStream<[Message], Error> {
        repo.messagesStream(chatId: chatId)
    }
}

public struct SendMessageUseCase {
    let repo: ChatRepository
    public init(repo: ChatRepository) { self.repo = repo }
    public func callAsFunction(chatId: String, sender: ChatUser, text: String) async throws {
        let msg = Message(chatId: chatId, senderId: sender.id, kind: .text, text: text)
        try await repo.send(message: msg)
    }
}

public struct CreateChatUseCase {
    let repo: ChatRepository
    public init(repo: ChatRepository) { self.repo = repo }
    public func callAsFunction(members: [ChatUser]) async throws -> Chat {
        try await repo.createChat(members: members)
    }
}
