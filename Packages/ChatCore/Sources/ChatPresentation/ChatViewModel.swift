import Foundation
import Combine
import ChatDomain

@MainActor
public final class ChatViewModel: ObservableObject {
    public enum State: Equatable { case idle, loading, loaded, error(String) }

    @Published public private(set) var state: State = .idle
    @Published public private(set) var messages: [Message] = []
    @Published public var draft: String = ""

    private let observeMessages: ObserveMessagesUseCase
    private let sendMessage: SendMessageUseCase
    private let chatId: String
    private let currentUser: ChatUser

    private var streamTask: Task<Void, Never>?

    public init(chatId: String,
                currentUser: ChatUser,
                observeMessages: ObserveMessagesUseCase,
                sendMessage: SendMessageUseCase) {
        self.chatId = chatId
        self.currentUser = currentUser
        self.observeMessages = observeMessages
        self.sendMessage = sendMessage
    }

    deinit { streamTask?.cancel() }

    public func start() {
        guard streamTask == nil else { return }
        state = .loading
        streamTask = Task { [weak self] in
            guard let self else { return }
            do {
                for try await list in observeMessages(chatId: chatId) {
                    await MainActor.run {
                        self.messages = list.sorted(by: { $0.sentAt < $1.sentAt })
                        self.state = .loaded
                    }
                }
            } catch {
                await MainActor.run { self.state = .error(error.localizedDescription) }
            }
        }
    }

    public func send() async {
        let text = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        do {
            try await sendMessage(chatId: chatId, sender: currentUser, text: text)
            draft = ""
        } catch {
            state = .error(error.localizedDescription)
        }
    }
}
