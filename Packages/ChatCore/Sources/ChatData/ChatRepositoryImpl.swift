import Foundation
import ChatDomain

public final class ChatRepositoryImpl: ChatRepository {
    private let dataSource: ChatDataSource

    public init(dataSource: ChatDataSource) {
        self.dataSource = dataSource
    }

    public func messagesStream(chatId: String) -> AsyncThrowingStream<[Message], Error> {
        dataSource.messagesStream(chatId: chatId)
    }

    public func send(message: Message) async throws {
        try await dataSource.send(message: message)
    }

    public func createChat(members: [ChatUser]) async throws -> Chat {
        try await dataSource.createChat(members: members)
    }

    public func getAllChats() async throws -> [Chat] {
        try await dataSource.getAllChats()
    }

    public func getLatestMessage(chatId: String) async throws -> Message? {
        try await dataSource.getLatestMessage(chatId: chatId)
    }
}

