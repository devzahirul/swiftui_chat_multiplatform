import Foundation
import Combine
import ChatDomain

@MainActor
public class ChatListViewModel: ObservableObject {
    @Published public var chats: [ChatWithPreview] = []
    @Published public var isLoading = false
    @Published public var error: String?

    private let getAllChats: GetAllChatsUseCase
    private let getLatestMessage: GetLatestMessageUseCase

    public init(getAllChats: GetAllChatsUseCase, getLatestMessage: GetLatestMessageUseCase) {
        self.getAllChats = getAllChats
        self.getLatestMessage = getLatestMessage
    }

    public func loadChats() async {
        isLoading = true
        error = nil

        do {
            let allChats = try await getAllChats()
            var chatsWithPreview: [ChatWithPreview] = []

            for chat in allChats {
                let latestMessage = try await getLatestMessage(chatId: chat.id)
                chatsWithPreview.append(ChatWithPreview(
                    chat: chat,
                    latestMessage: latestMessage,
                    title: "Chat \(chat.id.prefix(8))",
                    subtitle: latestMessage?.text ?? "No messages yet",
                    timestamp: latestMessage?.sentAt ?? chat.createdAt,
                    unreadCount: 0
                ))
            }

            self.chats = chatsWithPreview.sorted { $0.timestamp > $1.timestamp }
        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
    }

    public func refresh() {
        Task { await loadChats() }
    }
}

public struct ChatWithPreview: Identifiable {
    public let id: String
    public let chat: Chat
    public let latestMessage: Message?
    public let title: String
    public let subtitle: String
    public let timestamp: Date
    public let unreadCount: Int

    public init(chat: Chat, latestMessage: Message?, title: String, subtitle: String, timestamp: Date, unreadCount: Int) {
        self.id = chat.id
        self.chat = chat
        self.latestMessage = latestMessage
        self.title = title
        self.subtitle = subtitle
        self.timestamp = timestamp
        self.unreadCount = unreadCount
    }
}

