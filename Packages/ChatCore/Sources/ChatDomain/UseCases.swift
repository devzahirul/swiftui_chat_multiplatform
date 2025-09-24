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

public struct GetAllChatsUseCase {
    let repo: ChatRepository
    public init(repo: ChatRepository) { self.repo = repo }
    public func callAsFunction() async throws -> [Chat] {
        try await repo.getAllChats()
    }
}

public struct GetLatestMessageUseCase {
    let repo: ChatRepository
    public init(repo: ChatRepository) { self.repo = repo }
    public func callAsFunction(chatId: String) async throws -> Message? {
        try await repo.getLatestMessage(chatId: chatId)
    }
}

// MARK: - Presence & Typing Use Cases

public struct ObservePresenceUseCase {
    let repo: PresenceRepository
    public init(repo: PresenceRepository) { self.repo = repo }
    public func callAsFunction(userId: String) -> AsyncThrowingStream<Presence, Error> {
        repo.presenceStream(userId: userId)
    }
}

public struct UpdatePresenceUseCase {
    let repo: PresenceRepository
    public init(repo: PresenceRepository) { self.repo = repo }
    public func callAsFunction(userId: String, isOnline: Bool) async throws {
        try await repo.setPresence(userId: userId, isOnline: isOnline)
    }
}

public struct ObserveTypingUseCase {
    let repo: TypingRepository
    public init(repo: TypingRepository) { self.repo = repo }
    public func callAsFunction(chatId: String) -> AsyncThrowingStream<TypingIndicator, Error> {
        repo.typingStream(chatId: chatId)
    }
}

public struct SetTypingUseCase {
    let repo: TypingRepository
    public init(repo: TypingRepository) { self.repo = repo }
    public func callAsFunction(chatId: String, userId: String, isTyping: Bool) async throws {
        try await repo.setTyping(chatId: chatId, userId: userId, isTyping: isTyping)
    }
}
