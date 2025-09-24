import XCTest
@testable import ChatPresentation
@testable import ChatDomain
import ChatTestUtils
import ChatData

final class ChatViewModelTests: XCTestCase {
    @MainActor
    func test_start_and_send_updates_messages() async throws {
    let repo = ChatRepositoryImpl(dataSource: InMemoryChatDataSource())
        let container = ChatContainer(repo: repo)
        let u1 = Fixtures.user(name: "Me")
        let u2 = Fixtures.user(name: "You")
        let chat = try await container.createChat(members: [u1, u2])
        let vm = ChatViewModel(chatId: chat.id, currentUser: u1, observeMessages: container.observeMessages, sendMessage: container.sendMessage)

        vm.start()
        XCTAssertEqual(vm.state, .loading)

        vm.draft = "Hello"
        await vm.send()

        // Allow runloop a moment
        try await Task.sleep(nanoseconds: 50_000_000)

        XCTAssertEqual(vm.messages.count, 1)
        XCTAssertEqual(vm.messages.first?.text, "Hello")
        XCTAssertEqual(vm.state, .loaded)
    }
}
