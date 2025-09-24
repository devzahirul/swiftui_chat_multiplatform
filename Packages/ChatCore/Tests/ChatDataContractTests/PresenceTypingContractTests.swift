import XCTest
import ChatDomain
@testable import ChatData

final class PresenceTypingContractTests: XCTestCase {
    func test_presence_stream_receives_updates() async throws {
        let repo = InMemoryPresenceRepository()
        let userId = "u1"
        let exp = expectation(description: "presence")
        var values: [Presence] = []

        let task = Task {
            for try await p in repo.presenceStream(userId: userId) {
                values.append(p)
                if values.count == 1 { exp.fulfill() }
            }
        }

        try await repo.setPresence(userId: userId, isOnline: true)
        await fulfillment(of: [exp], timeout: 2.0)
        task.cancel()
        XCTAssertEqual(values.first?.isOnline, true)
    }

    func test_typing_stream_receives_updates() async throws {
        let repo = InMemoryTypingRepository()
        let chatId = "c1"
        let exp = expectation(description: "typing")
        var values: [TypingIndicator] = []

        let task = Task {
            for try await t in repo.typingStream(chatId: chatId) {
                values.append(t)
                if values.count == 1 { exp.fulfill() }
            }
        }
        try await repo.setTyping(chatId: chatId, userId: "u1", isTyping: true)
        await fulfillment(of: [exp], timeout: 2.0)
        task.cancel()
        XCTAssertEqual(values.first?.isTyping, true)
    }
}

