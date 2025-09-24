import SwiftUI
import ChatDomain
import ChatPresentation
import ChatUI
import ChatData

final class TypingPresenceController: ObservableObject {
    @Published var isTyping = false
    private let typingRepo = InMemoryTypingRepository()
    private var task: Task<Void, Never>?

    func start(chatId: String, currentUserId: String) {
        task?.cancel()
        task = Task { [weak self] in
            do {
                for try await ind in typingRepo.typingStream(chatId: chatId) {
                    guard ind.userId != currentUserId else { continue }
                    await MainActor.run { self?.isTyping = ind.isTyping }
                }
            } catch { /* ignore in demo */ }
        }
    }

    func setTyping(chatId: String, userId: String, isTyping: Bool) {
        Task { try? await typingRepo.setTyping(chatId: chatId, userId: userId, isTyping: isTyping) }
    }

    deinit { task?.cancel() }
}

struct TypingDotsView: View {
    @State private var phase: CGFloat = 0
    var body: some View {
        HStack(spacing: 4) {
            Circle().frame(width: 6, height: 6)
            Circle().frame(width: 6, height: 6)
            Circle().frame(width: 6, height: 6)
        }
        .foregroundColor(.secondary)
        .opacity(0.7)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.9).repeatForever()) { phase = 1 }
        }
    }
}

struct CustomChatScreen: View {
    let chatId: String
    let currentUser: ChatUser
    @StateObject private var vm: ChatViewModel
    @StateObject private var typing = TypingPresenceController()

    init(chatId: String, currentUser: ChatUser) {
        self.chatId = chatId
        self.currentUser = currentUser
        let observe: ObserveMessagesUseCase = resolve()
        let send: SendMessageUseCase = resolve()
        _vm = StateObject(wrappedValue: ChatViewModel(chatId: chatId, currentUser: currentUser, observeMessages: observe, sendMessage: send))
    }

    var body: some View {
        MessengerChatView(
            viewModel: vm,
            currentUserId: currentUser.id,
            chatTitle: "Chat",
            isOnline: false,
            headerLeading: { EmptyView() },
            headerTrailing: { DefaultHeaderTrailing() },
            messageAccessory: { _, isOutgoing in
                if !isOutgoing && typing.isTyping { TypingDotsView().padding(.horizontal) } else { EmptyView() }
            },
            inputAccessory: { EmptyView() },
            onTyping: { isTyping in typing.setTyping(chatId: chatId, userId: currentUser.id, isTyping: isTyping) }
        )
        .onAppear { typing.start(chatId: chatId, currentUserId: currentUser.id) }
    }
}

