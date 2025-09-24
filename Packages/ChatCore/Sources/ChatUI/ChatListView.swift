import SwiftUI
import ChatDomain
import ChatPresentation
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

public struct MessengerChatListView<Header: View, Search: View, Empty: View, RowAccessory: View>: View {
    @ObservedObject var viewModel: ChatListViewModel
    let currentUser: ChatUser
    let onChatSelected: (Chat) -> Void
    let onNewChatTapped: (() -> Void)?
    let onHeaderAvatarTapped: (() -> Void)?
    let headerContent: () -> Header
    let searchContent: () -> Search
    let emptyState: () -> Empty
    let rowAccessory: (ChatWithPreview) -> RowAccessory

    @Environment(\.messengerTheme) private var theme
    @State private var searchText: String = ""

    public init(
        viewModel: ChatListViewModel,
        currentUser: ChatUser,
        onChatSelected: @escaping (Chat) -> Void,
        onNewChatTapped: (() -> Void)? = nil,
        onHeaderAvatarTapped: (() -> Void)? = nil,
        @ViewBuilder headerContent: @escaping () -> Header,
        @ViewBuilder searchContent: @escaping () -> Search,
        @ViewBuilder emptyState: @escaping () -> Empty,
        @ViewBuilder rowAccessory: @escaping (ChatWithPreview) -> RowAccessory
    ) {
        self.viewModel = viewModel
        self.currentUser = currentUser
        self.onChatSelected = onChatSelected
        self.onNewChatTapped = onNewChatTapped
        self.onHeaderAvatarTapped = onHeaderAvatarTapped
        self.headerContent = headerContent
        self.searchContent = searchContent
        self.emptyState = emptyState
        self.rowAccessory = rowAccessory
    }

    @Environment(\.scenePhase) private var scenePhase

    public var body: some View {
        VStack(spacing: 0) {
            headerContent()
            searchContent()
            messengerContent
        }
        .background(theme.background)
        .task { await viewModel.loadChats() }
        .refreshable { await viewModel.loadChats() }
        .onChange(of: scenePhase) { newValue in
            if newValue == .active {
                Task { await viewModel.loadChats() }
            }
        }
    }

    private var messengerHeader: some View {
        HStack(spacing: 16) {
            // Current user avatar (single initial, camel-case uppercased)
            if let onHeaderAvatarTapped {
                Button(action: onHeaderAvatarTapped) {
                    MessengerAvatar.small(
                        initials: firstInitial(for: currentUser.displayName)
                    )
                }
                .buttonStyle(.plain)
            } else {
                MessengerAvatar.small(
                    initials: firstInitial(for: currentUser.displayName)
                )
            }

            Text("Chats")
                .font(MessengerTheme.Typography.headerTitle)
                .foregroundColor(theme.text)
                .frame(maxWidth: .infinity, alignment: .leading)

            // Camera button (like Messenger Stories)
            Button(action: {}) {
                Image(systemName: "camera")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(theme.text)
                    .frame(width: 36, height: 36)
                    .background(
                        Circle()
                            .fill(theme.searchBackground)
                    )
            }
            .buttonStyle(.plain)

            // New chat button
            Button(action: { onNewChatTapped?() }) {
                Image(systemName: "square.and.pencil")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(theme.text)
                    .frame(width: 36, height: 36)
                    .background(
                        Circle()
                            .fill(theme.searchBackground)
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, MessengerTheme.Spacing.defaultPadding)
        .padding(.vertical, 12)
    }

    private var messengerSearchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.secondary)

            TextField("Search", text: $searchText)
                .font(.system(size: 16))
                .textFieldStyle(.plain)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(theme.searchBackground)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .padding(.horizontal, MessengerTheme.Spacing.defaultPadding)
        .padding(.bottom, 8)
    }

    private var messengerContent: some View {
        Group {
            if viewModel.isLoading {
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.2)
                    Text("Loading chats…")
                        .font(MessengerTheme.Typography.chatSubtitle)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if filteredChats.isEmpty {
                emptyState()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(filteredChats) { item in
                            Button(action: { onChatSelected(item.chat) }) {
                                HStack(spacing: 8) {
                                    MessengerChatRow(item: item, currentUserId: currentUser.id, isOnline: false)
                                    rowAccessory(item)
                                }
                            }
                            .buttonStyle(.plain)
                            .contextMenu {
                                Button("Delete Chat", role: .destructive) {
                                    // TODO: Delete chat
                                }
                                Button("Mute") {
                                    // TODO: Mute chat
                                }
                                Button("Mark as Read") {
                                    // TODO: Mark as read
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    private var filteredChats: [ChatWithPreview] {
        guard !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return viewModel.chats }
        let q = searchText.lowercased()
        return viewModel.chats.filter { $0.title.lowercased().contains(q) || $0.subtitle.lowercased().contains(q) }
    }

    private func firstInitial(for name: String) -> String {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let ch = trimmed.first else { return "?" }
        return String(ch).uppercased()
    }
}

// Legacy ChatListView for backward compatibility
public typealias ChatListView = MessengerChatListView<EmptyView, EmptyView, DefaultEmptyState, DefaultRowAccessory>

// Defaults to keep API easy to use
public extension MessengerChatListView where Header == DefaultHeader, Search == DefaultSearchBar, Empty == DefaultEmptyState, RowAccessory == DefaultRowAccessory {
    init(
        viewModel: ChatListViewModel,
        currentUser: ChatUser,
        onChatSelected: @escaping (Chat) -> Void,
        onNewChatTapped: (() -> Void)? = nil,
        onHeaderAvatarTapped: (() -> Void)? = nil
    ) {
        self.init(
            viewModel: viewModel,
            currentUser: currentUser,
            onChatSelected: onChatSelected,
            onNewChatTapped: onNewChatTapped,
            onHeaderAvatarTapped: onHeaderAvatarTapped,
            headerContent: { DefaultHeader(currentUser: currentUser, onNewChatTapped: onNewChatTapped, onHeaderAvatarTapped: onHeaderAvatarTapped) },
            searchContent: { DefaultSearchBar() },
            emptyState: { DefaultEmptyState() },
            rowAccessory: { _ in DefaultRowAccessory() }
        )
    }
}

public struct DefaultHeader: View {
    let currentUser: ChatUser
    let onNewChatTapped: (() -> Void)?
    let onHeaderAvatarTapped: (() -> Void)?
    @Environment(\.messengerTheme) private var theme

    public var body: some View {
        HStack(spacing: 16) {
            if let onHeaderAvatarTapped {
                Button(action: onHeaderAvatarTapped) {
                    MessengerAvatar.small(initials: firstInitial(for: currentUser.displayName))
                }.buttonStyle(.plain)
            } else {
                MessengerAvatar.small(initials: firstInitial(for: currentUser.displayName))
            }

            Text("Chats")
                .font(MessengerTheme.Typography.headerTitle)
                .foregroundColor(theme.text)
                .frame(maxWidth: .infinity, alignment: .leading)

            Button(action: {}) {
                Image(systemName: "camera")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(theme.text)
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(theme.searchBackground))
            }.buttonStyle(.plain)

            Button(action: { onNewChatTapped?() }) {
                Image(systemName: "square.and.pencil")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(theme.text)
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(theme.searchBackground))
            }.buttonStyle(.plain)
        }
        .padding(.horizontal, MessengerTheme.Spacing.defaultPadding)
        .padding(.vertical, 12)
    }

    private func firstInitial(for name: String) -> String {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let ch = trimmed.first else { return "?" }
        return String(ch).uppercased()
    }
}

public struct DefaultSearchBar: View {
    @Environment(\.messengerTheme) private var theme
    @State private var text: String = ""

    public var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass").font(.system(size: 16, weight: .medium)).foregroundColor(.secondary)
            TextField("Search", text: $text).font(.system(size: 16)).textFieldStyle(.plain)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(theme.searchBackground)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .padding(.horizontal, MessengerTheme.Spacing.defaultPadding)
        .padding(.bottom, 8)
    }
}

public struct DefaultEmptyState: View {
    @Environment(\.messengerTheme) private var theme
    public init() {}
    public var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "message.circle").font(.system(size: 64)).foregroundColor(.secondary.opacity(0.6))
            VStack(spacing: 4) {
                Text("No messages yet").font(MessengerTheme.Typography.chatTitle).foregroundColor(theme.text)
                Text("Start a new conversation").font(MessengerTheme.Typography.chatSubtitle).foregroundColor(.secondary)
            }
        }
    }
}

public struct DefaultRowAccessory: View { public init() {} public var body: some View { EmptyView() } }
