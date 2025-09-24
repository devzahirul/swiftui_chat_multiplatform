import Foundation
import ChatDomain

// Abstraction over persistence/transport for chat data.
// Implementations may be in-memory, local DB, or network-backed.
public protocol ChatDataSource {
    // Streams
    func messagesStream(chatId: String) -> AsyncThrowingStream<[Message], Error>

    // Commands
    func send(message: Message) async throws
    func createChat(members: [ChatUser]) async throws -> Chat

    // Queries
    func getAllChats() async throws -> [Chat]
    func getLatestMessage(chatId: String) async throws -> Message?
}

