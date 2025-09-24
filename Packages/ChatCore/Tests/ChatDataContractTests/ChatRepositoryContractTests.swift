import XCTest
import ChatDomain
@testable import ChatData

final class ChatRepositoryContractTests: XCTestCase {
    func test_createChat_and_send_and_observe() async throws {
        let repo = ChatRepositoryImpl(dataSource: InMemoryChatDataSource())
        let me = ChatUser(id: "me", displayName: "Me")
        let peer = ChatUser(id: "u2", displayName: "Peer")
        let chat = try await repo.createChat(members: [me, peer])

        let exp = expectation(description: "observe")
        var received: [Message] = []

        let task = Task {
            for try await msg in repo.observeMessages(chatId: chat.id) {
                received.append(msg)
                if received.count == 1 { exp.fulfill() }
            }
        }

        _ = try await repo.sendMessage(chatId: chat.id, author: me, text: "Hi")
        await fulfillment(of: [exp], timeout: 2.0)
        task.cancel()

        XCTAssertEqual(received.first?.text, "Hi")
    }
}

