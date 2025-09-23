import XCTest
@testable import ChatDomain
import ChatTestUtils

final class InMemoryChatRepositoryTests: XCTestCase {
    func test_createChat_and_send_and_stream() async throws {
    let repo = InMemoryChatRepository()
        let u1 = Fixtures.user(name: "A")
        let u2 = Fixtures.user(name: "B")
        let chat = try await repo.createChat(members: [u1, u2])

    var iterator = repo.messagesStream(chatId: chat.id).makeAsyncIterator()
        // First emission is empty
        let first = try await iterator.next()
        XCTAssertEqual(first?.count, 0)

        try await repo.send(message: Fixtures.message(chatId: chat.id, senderId: u1.id, text: "Hi"))
        let second = try await iterator.next()
        XCTAssertEqual(second?.count, 1)
        XCTAssertEqual(second?.first?.text, "Hi")
    }
}
