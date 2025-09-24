import SwiftUI
import ChatDomain
import ChatPresentation
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

public struct MessengerChatView<HeaderLeading: View, HeaderTrailing: View, MessageAccessory: View, InputAccessory: View>: View {
    @ObservedObject var vm: ChatViewModel
    let currentUserId: String
    let chatTitle: String
    let isOnline: Bool
    let headerLeading: () -> HeaderLeading
    let headerTrailing: () -> HeaderTrailing
    let messageAccessory: (Message, Bool) -> MessageAccessory
    let inputAccessory: () -> InputAccessory

    @Environment(\.messengerTheme) private var theme
    @Environment(\.dismiss) private var dismiss

    public init(
        viewModel: ChatViewModel,
        currentUserId: String,
        chatTitle: String = "Chat",
        isOnline: Bool = false,
        @ViewBuilder headerLeading: @escaping () -> HeaderLeading,
        @ViewBuilder headerTrailing: @escaping () -> HeaderTrailing,
        @ViewBuilder messageAccessory: @escaping (Message, Bool) -> MessageAccessory,
        @ViewBuilder inputAccessory: @escaping () -> InputAccessory
    ) {
        self.vm = viewModel
        self.currentUserId = currentUserId
        self.chatTitle = chatTitle
        self.isOnline = isOnline
        self.headerLeading = headerLeading
        self.headerTrailing = headerTrailing
        self.messageAccessory = messageAccessory
        self.inputAccessory = inputAccessory
    }

    public var body: some View {
        VStack(spacing: 0) {
            messengerHeader

            messagesContainer

            inputAccessory()
            MessengerInputField(
                text: $vm.draft,
                onSend: {
                    Task { await vm.send() }
                },
                onTyping: { isTyping in
                    // Handle typing indicator
                }
            )
        }
        .background(theme.background)
        #if canImport(UIKit)
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        #endif
        .onAppear { vm.start() }
    }

    private var messengerHeader: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                // Back button
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(theme.outgoing)
                        .frame(width: 32, height: 32)
                }
                .buttonStyle(.plain)

                // Chat info
                headerLeading()
                HStack(spacing: 12) {
                    MessengerAvatar.medium(
                        initials: chatInitials,
                        isOnline: isOnline
                    )

                    VStack(alignment: .leading, spacing: 1) {
                        Text(chatTitle)
                            .font(MessengerTheme.Typography.chatTitle)
                            .foregroundColor(theme.text)
                            .lineLimit(1)

                        if isOnline {
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(theme.activeStatus)
                                    .frame(width: 8, height: 8)

                                Text("Active now")
                                    .font(.system(size: 13))
                                    .foregroundColor(.secondary)
                            }
                        }
                    }

                    Spacer()
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    // Navigate to chat info
                }

                // Trailing actions
                headerTrailing()
            }
            .padding(.horizontal, MessengerTheme.Spacing.defaultPadding)
            .padding(.vertical, 8)
            .background(theme.background)

            Rectangle()
                .fill(theme.separator)
                .frame(height: 0.5)
        }
    }

    private var messagesContainer: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 2) {
                    ForEach(groupedMessages, id: \.0) { (_, messages) in
                        ForEach(Array(messages.enumerated()), id: \.element.id) { index, message in
                            let isLastInGroup = index == messages.count - 1
                            let shouldShowTimestamp = shouldShowTimestamp(for: message, in: messages, at: index)

                            MessengerMessageRow(
                                message: message,
                                isOutgoing: message.senderId == currentUserId,
                                isLastInGroup: isLastInGroup,
                                showTimestamp: shouldShowTimestamp
                            )
                            .id(message.id)

                            // Accessory below each message group item
                            messageAccessory(message, message.senderId == currentUserId)
                        }
                    }

                    // Bottom spacer for better scrolling experience
                    Color.clear
                        .frame(height: 8)
                        .id("bottom")
                }
                .padding(.top, 8)
            }
            .background(theme.background)
            .onChange(of: vm.messages.map { $0.id }) { _ in
                withAnimation(.easeInOut(duration: 0.3)) {
                    proxy.scrollTo("bottom", anchor: .bottom)
                }
            }
            .onTapGesture {
                // Dismiss keyboard when tapping on messages
                hideKeyboard()
            }
        }
    }

    // Group messages by sender and time proximity
    private var groupedMessages: [(String, [Message])] {
        let grouped = Dictionary(grouping: vm.messages) { message in
            "\(message.senderId)-\(timeGroup(for: message.sentAt))"
        }

        return grouped.sorted { lhs, rhs in
            guard let lhsFirst = lhs.value.first,
                  let rhsFirst = rhs.value.first else { return false }
            return lhsFirst.sentAt < rhsFirst.sentAt
        }.map { (key, messages) in
            (key, messages.sorted { $0.sentAt < $1.sentAt })
        }
    }

    private func timeGroup(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd-HHmm"
        let rounded = Calendar.current.date(byAdding: .minute, value: -Int(date.timeIntervalSince1970.truncatingRemainder(dividingBy: 300)), to: date) ?? date
        return formatter.string(from: rounded)
    }

    private func shouldShowTimestamp(for message: Message, in messages: [Message], at index: Int) -> Bool {
        guard index < messages.count - 1 else { return true }
        let nextMessage = messages[index + 1]
        return message.sentAt.timeIntervalSince(nextMessage.sentAt) > 300 // 5 minutes
    }

    private var chatInitials: String {
        let parts = chatTitle.split(separator: " ")
        let first = parts.first?.first.map(String.init) ?? "C"
        let second = parts.dropFirst().first?.first.map(String.init) ?? ""
        return (first + second).uppercased()
    }

    private func hideKeyboard() {
        #if canImport(UIKit)
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        #endif
    }
}

// Legacy ChatView for backward compatibility
public typealias ChatView = MessengerChatView<EmptyView, DefaultHeaderTrailing, DefaultMessageAccessory, EmptyView>

// Defaults for slots
public struct DefaultHeaderTrailing: View {
    @Environment(\.messengerTheme) private var theme
    public init() {}
    public var body: some View {
        Button(action: {}) {
            Image(systemName: "info.circle").font(.system(size: 20)).foregroundColor(theme.outgoing).frame(width: 32, height: 32)
        }.buttonStyle(.plain)
    }
}

public struct DefaultMessageAccessory: View {
    public init() {}
    public var body: some View { EmptyView() }
}

// Convenience init retaining old signature
public extension MessengerChatView where HeaderLeading == EmptyView, HeaderTrailing == DefaultHeaderTrailing, MessageAccessory == DefaultMessageAccessory, InputAccessory == EmptyView {
    init(viewModel: ChatViewModel, currentUserId: String, chatTitle: String = "Chat", isOnline: Bool = false) {
        self.init(
            viewModel: viewModel,
            currentUserId: currentUserId,
            chatTitle: chatTitle,
            isOnline: isOnline,
            headerLeading: { EmptyView() },
            headerTrailing: { DefaultHeaderTrailing() },
            messageAccessory: { _,_ in DefaultMessageAccessory() },
            inputAccessory: { EmptyView() }
        )
    }
}
