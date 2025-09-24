import SwiftUI
import ChatDomain
import ChatPresentation

public struct MessengerChatRow: View {
    let item: ChatWithPreview
    let currentUserId: String
    let isOnline: Bool
    let showImage: Bool

    @Environment(\.messengerTheme) private var theme

    public init(item: ChatWithPreview, currentUserId: String, isOnline: Bool = false, showImage: Bool = true) {
        self.item = item
        self.currentUserId = currentUserId
        self.isOnline = isOnline
        self.showImage = showImage
    }

    public var body: some View {
        HStack(spacing: 12) {
            if showImage {
                MessengerAvatar(
                    initials: avatarInitials,
                    size: MessengerTheme.Spacing.avatarSize,
                    isOnline: isOnline,
                    showStatusIndicator: true
                )
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .firstTextBaseline) {
                    Text(item.title)
                        .font(MessengerTheme.Typography.chatTitle)
                        .foregroundColor(theme.text)
                        .fontWeight(item.unreadCount > 0 ? .semibold : .regular)
                        .lineLimit(1)

                    Spacer()

                    HStack(spacing: 4) {
                        if item.unreadCount == 0 {
                            deliveryStatusIcon
                        }

                        Text(timeText)
                            .font(MessengerTheme.Typography.timestamp)
                            .foregroundColor(.secondary)
                    }
                }

                HStack(alignment: .center, spacing: 8) {
                    Text(subtitleText)
                        .font(MessengerTheme.Typography.chatSubtitle)
                        .foregroundColor(item.unreadCount > 0 ? theme.text : .secondary)
                        .fontWeight(item.unreadCount > 0 ? .medium : .regular)
                        .lineLimit(1)

                    Spacer()

                    if item.unreadCount > 0 {
                        unreadBadge
                    }
                }
            }
        }
        .contentShape(Rectangle())
        .frame(height: MessengerTheme.Spacing.chatRowHeight)
        .padding(.horizontal, MessengerTheme.Spacing.defaultPadding)
    }

    private var avatarInitials: String {
        let s = item.title.trimmingCharacters(in: .whitespaces)
        let first = s.first.map { String($0) } ?? "C"
        let second = s.dropFirst().first.map { String($0) } ?? ""
        return (first + second).uppercased()
    }

    private var subtitleText: String {
        let prefix = isLastMessageFromCurrentUser ? "You: " : ""
        return prefix + item.subtitle
    }

    private var isLastMessageFromCurrentUser: Bool {
        guard let latestMessage = item.latestMessage else { return false }
        return latestMessage.senderId == currentUserId
    }

    private var timeText: String {
        let date = item.timestamp
        let calendar = Calendar.current

        if calendar.isDateInToday(date) {
            let formatter = DateFormatter()
            formatter.dateFormat = "h:mm a"
            return formatter.string(from: date)
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else if calendar.isDate(date, equalTo: Date(), toGranularity: .weekOfYear) {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE"
            return formatter.string(from: date)
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "M/d/yy"
            return formatter.string(from: date)
        }
    }

    private var unreadBadge: some View {
        Text(unreadCountText)
            .font(MessengerTheme.Typography.unreadCount)
            .foregroundColor(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(
                Capsule()
                    .fill(theme.outgoing)
            )
            .frame(minWidth: 18)
    }

    private var unreadCountText: String {
        if item.unreadCount > 99 {
            return "99+"
        } else {
            return "\(item.unreadCount)"
        }
    }

    @ViewBuilder
    private var deliveryStatusIcon: some View {
        if isLastMessageFromCurrentUser {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 12))
                .foregroundColor(theme.outgoing)
        }
    }
}

// MARK: - Preview Support
#if DEBUG
extension MessengerChatRow {
    static var preview: MessengerChatRow {
        let sampleMessage = Message(
            id: "msg1",
            chatId: "1",
            senderId: "user1",
            sentAt: Date(),
            kind: .text,
            text: "Hey, how are you doing?"
        )

        let chatWithPreview = ChatWithPreview(
            chat: Chat(id: "1", memberIds: ["user1", "user2"], createdAt: Date()),
            latestMessage: sampleMessage,
            title: "John Doe",
            subtitle: "Hey, how are you doing?",
            timestamp: Date(),
            unreadCount: 2
        )

        return MessengerChatRow(
            item: chatWithPreview,
            currentUserId: "user2",
            isOnline: true
        )
    }
}
#endif