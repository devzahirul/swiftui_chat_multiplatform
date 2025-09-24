import SwiftUI
import ChatDomain
import ChatPresentation
import ChatUI
import ChatData

final class RealtimeController: ObservableObject {
    @Published var isTyping = false
    @Published var isPeerOnline = false
    private let typingRepo = InMemoryTypingRepository()
    private let presenceRepo = InMemoryPresenceRepository()
    private var typingTask: Task<Void, Never>?
    private var presenceTask: Task<Void, Never>?

    func start(chat: Chat, currentUserId: String) {
        let chatId = chat.id
        let peerId = chat.memberIds.first { $0 != currentUserId }

        typingTask?.cancel()
        typingTask = Task { [weak self] in
            do {
                for try await ind in typingRepo.typingStream(chatId: chatId) {
                    guard ind.userId != currentUserId else { continue }
                    await MainActor.run { self?.isTyping = ind.isTyping }
                }
            } catch { /* ignore in demo */ }
        }

        presenceTask?.cancel()
        if let peerId {
            presenceTask = Task { [weak self] in
                do {
                    for try await p in presenceRepo.presenceStream(userId: peerId) {
                        await MainActor.run { self?.isPeerOnline = p.isOnline }
                    }
                } catch { /* ignore in demo */ }
            }
        }

        // Mark current user online for demo
        Task { try? await presenceRepo.setPresence(userId: currentUserId, isOnline: true) }
    }

    func setTyping(chatId: String, userId: String, isTyping: Bool) {
        Task { try? await typingRepo.setTyping(chatId: chatId, userId: userId, isTyping: isTyping) }
    }

    deinit { typingTask?.cancel(); presenceTask?.cancel() }
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

struct PresenceBadgeView: View {
    let isOnline: Bool
    var body: some View {
        HStack(spacing: 6) {
            Circle().fill(isOnline ? Color.green : Color.gray).frame(width: 8, height: 8)
            Text(isOnline ? "Active now" : "Offline").font(.footnote).foregroundColor(.secondary)
        }
    }
}

struct CustomChatScreen: View {
    let chat: Chat
    let currentUser: ChatUser
    @StateObject private var vm: ChatViewModel
    @StateObject private var realtime = RealtimeController()

    init(chat: Chat, currentUser: ChatUser) {
        self.chat = chat
        self.currentUser = currentUser
        let observe: ObserveMessagesUseCase = resolve()
        let send: SendMessageUseCase = resolve()
        _vm = StateObject(wrappedValue: ChatViewModel(chatId: chat.id, currentUser: currentUser, observeMessages: observe, sendMessage: send))
    }

    var body: some View {
        MessengerChatView(
            viewModel: vm,
            currentUserId: currentUser.id,
            chatTitle: "Chat",
            isOnline: realtime.isPeerOnline,
            headerLeading: { EmptyView() },
            headerTrailing: { PresenceBadgeView(isOnline: realtime.isPeerOnline) },
            messageAccessory: { _, isOutgoing in
                if !isOutgoing && realtime.isTyping { TypingDotsView().padding(.horizontal) } else { EmptyView() }
            },
            inputAccessory: { EmptyView() },
            onTyping: { isTyping in realtime.setTyping(chatId: chat.id, userId: currentUser.id, isTyping: isTyping) }
        )
        .onAppear { realtime.start(chat: chat, currentUserId: currentUser.id) }
    }
}
