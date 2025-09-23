import Foundation

public protocol ChatRepository {
    // Chat streams
    func messagesStream(chatId: String) -> AsyncThrowingStream<[Message], Error>

    // Commands
    func send(message: Message) async throws
    func createChat(members: [ChatUser]) async throws -> Chat
}

public enum ChatError: Error, Equatable {
    case chatNotFound
    case permissionDenied
    case network
    case unknown
}
