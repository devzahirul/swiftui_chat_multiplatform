import SwiftUI
import ChatDomain

public struct MessengerMessageBubble: View {
    let message: Message
    let isOutgoing: Bool
    let showTail: Bool
    let showTimestamp: Bool

    @Environment(\.messengerTheme) private var theme

    public init(message: Message, isOutgoing: Bool, showTail: Bool = true, showTimestamp: Bool = false) {
        self.message = message
        self.isOutgoing = isOutgoing
        self.showTail = showTail
        self.showTimestamp = showTimestamp
    }

    public var body: some View {
        VStack(alignment: isOutgoing ? .trailing : .leading, spacing: 2) {
            HStack(alignment: .bottom, spacing: 4) {
                if isOutgoing {
                    Spacer(minLength: 60)
                } else {
                    if !showTail {
                        Spacer()
                            .frame(width: 32)
                    }
                }

                VStack(alignment: isOutgoing ? .trailing : .leading, spacing: 2) {
                    messageBubble

                    if showTimestamp {
                        timestampView
                    }
                }

                if !isOutgoing {
                    Spacer(minLength: 60)
                }
            }
        }
    }

    private var messageBubble: some View {
        Text(message.text ?? "")
            .font(MessengerTheme.Typography.messageText)
            .foregroundColor(isOutgoing ? .white : theme.text)
            .padding(.horizontal, MessengerTheme.Spacing.messagePadding)
            .padding(.vertical, 10)
            .background {
                bubbleShape
                    .fill(isOutgoing ? theme.outgoing : theme.incoming)
            }
            .overlay {
                if !isOutgoing {
                    bubbleShape
                        .stroke(MessengerTheme.Effects.bubbleShadow, lineWidth: 0.5)
                }
            }
    }

    private var bubbleShape: some Shape {
        MessengerBubbleShape(
            isOutgoing: isOutgoing,
            showTail: showTail,
            cornerRadius: MessengerTheme.Spacing.messageBubbleRadius
        )
    }

    private var timestampView: some View {
        Text(timeString)
            .font(MessengerTheme.Typography.timestamp)
            .foregroundColor(.secondary)
            .padding(.horizontal, 8)
    }

    private var timeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: message.sentAt)
    }
}

public struct MessengerBubbleShape: Shape {
    let isOutgoing: Bool
    let showTail: Bool
    let cornerRadius: CGFloat

    public func path(in rect: CGRect) -> Path {
        var path = Path()
        let radius = cornerRadius

        if isOutgoing {
            // Outgoing bubble (blue, right-aligned)
            if showTail {
                // Rounded rectangle with tail on bottom-right
                path.addRoundedRect(
                    in: CGRect(x: 0, y: 0, width: rect.width - 6, height: rect.height),
                    cornerSize: CGSize(width: radius, height: radius)
                )
                // Add tail
                path.move(to: CGPoint(x: rect.width - 6, y: rect.height - 10))
                path.addLine(to: CGPoint(x: rect.width, y: rect.height))
                path.addLine(to: CGPoint(x: rect.width - 6, y: rect.height - 2))
            } else {
                path.addRoundedRect(in: rect, cornerSize: CGSize(width: radius, height: radius))
            }
        } else {
            // Incoming bubble (gray, left-aligned)
            if showTail {
                // Rounded rectangle with tail on bottom-left
                path.addRoundedRect(
                    in: CGRect(x: 6, y: 0, width: rect.width - 6, height: rect.height),
                    cornerSize: CGSize(width: radius, height: radius)
                )
                // Add tail
                path.move(to: CGPoint(x: 6, y: rect.height - 10))
                path.addLine(to: CGPoint(x: 0, y: rect.height))
                path.addLine(to: CGPoint(x: 6, y: rect.height - 2))
            } else {
                path.addRoundedRect(in: rect, cornerSize: CGSize(width: radius, height: radius))
            }
        }

        return path
    }
}

// Legacy MessageRow for backward compatibility
public typealias MessageRow = MessengerMessageRow

public struct MessengerMessageRow: View {
    let message: Message
    let isOutgoing: Bool
    let isLastInGroup: Bool
    let showTimestamp: Bool

    public init(message: Message, isOutgoing: Bool, isLastInGroup: Bool = true, showTimestamp: Bool = false) {
        self.message = message
        self.isOutgoing = isOutgoing
        self.isLastInGroup = isLastInGroup
        self.showTimestamp = showTimestamp
    }

    public var body: some View {
        MessengerMessageBubble(
            message: message,
            isOutgoing: isOutgoing,
            showTail: isLastInGroup,
            showTimestamp: showTimestamp
        )
        .padding(.horizontal, MessengerTheme.Spacing.defaultPadding)
        .padding(.vertical, 1)
    }
}
