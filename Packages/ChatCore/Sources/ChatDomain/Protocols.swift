import Foundation

public protocol ChatRepository {
    // Chat streams
    func messagesStream(chatId: String) -> AsyncThrowingStream<[Message], Error>

    // Commands
    func send(message: Message) async throws
    func createChat(members: [ChatUser]) async throws -> Chat

    // Queries
    func getAllChats() async throws -> [Chat]
    func getLatestMessage(chatId: String) async throws -> Message?
}

public enum ChatError: Error, Equatable {
    case chatNotFound
    case permissionDenied
    case network
    case unknown
}

// MARK: - Presence & Typing

public protocol PresenceRepository {
    func presenceStream(userId: String) -> AsyncThrowingStream<Presence, Error>
    func setPresence(userId: String, isOnline: Bool) async throws
}

public protocol TypingRepository {
    func typingStream(chatId: String) -> AsyncThrowingStream<TypingIndicator, Error>
    func setTyping(chatId: String, userId: String, isTyping: Bool) async throws
}
