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

// MARK: - Custom AvatarStyle for header
import ChatUI // ensure styles are available

struct GradientInitialAvatarStyle: AvatarStyle {
    func makeBody(_ configuration: AvatarConfiguration) -> some View {
        ZStack {
            Circle()
                .fill(LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))
            Text(configuration.initials.prefix(1).uppercased())
                .font(.system(size: configuration.size * 0.6, weight: .semibold))
                .foregroundColor(.white)
        }
        .frame(width: configuration.size, height: configuration.size)
        .overlay(alignment: .bottomTrailing) {
            if configuration.isOnline {
                Circle().fill(Color.green).frame(width: configuration.size * 0.28, height: configuration.size * 0.28)
                    .overlay(Circle().stroke(Color.white, lineWidth: 2))
                    .offset(x: configuration.size * 0.06, y: configuration.size * 0.06)
            }
        }
    }
}

final class UserPresenceController: ObservableObject {
    @Published var isOnline = false
    private let presenceRepo = InMemoryPresenceRepository()
    private var task: Task<Void, Never>?

    func start(userId: String) {
        task?.cancel()
        task = Task { [weak self] in
            do {
                for try await p in presenceRepo.presenceStream(userId: userId) {
                    await MainActor.run { self?.isOnline = p.isOnline }
                }
            } catch { }
        }
        // Mark as online for demo
        Task { try? await presenceRepo.setPresence(userId: userId, isOnline: true) }
    }

    deinit { task?.cancel() }
}

struct CustomHeaderView: View {
    let currentUser: ChatUser
    let onNewChatTapped: (() -> Void)?
    let onHeaderAvatarTapped: (() -> Void)?
    @StateObject private var presence = UserPresenceController()

    var body: some View {
        HStack(spacing: 16) {
            Button(action: { onHeaderAvatarTapped?() }) {
                AvatarView(
                    style: GradientInitialAvatarStyle(),
                    configuration: .init(
                        imageURL: nil,
                        initials: String(currentUser.displayName.prefix(1)),
                        size: 24,
                        isOnline: presence.isOnline
                    )
                )
            }
            .buttonStyle(.plain)

            Text("Chats")
                .font(MessengerTheme.Typography.headerTitle)
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)

            Button(action: {}) {
                Image(systemName: "camera")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.primary)
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(Color(white: 0.95)))
            }
            .buttonStyle(.plain)

            Button(action: { onNewChatTapped?() }) {
                Image(systemName: "square.and.pencil")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.primary)
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(Color(white: 0.95)))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, MessengerTheme.Spacing.defaultPadding)
        .padding(.vertical, 12)
        .onAppear { presence.start(userId: currentUser.id) }
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
