import SwiftUI
import ChatDomain
import ChatPresentation
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

public struct ChatListView: View {
    @ObservedObject var viewModel: ChatListViewModel
    let currentUser: ChatUser
    let onChatSelected: (Chat) -> Void
    let onNewChatTapped: (() -> Void)?

    @State private var searchText: String = ""

    public init(viewModel: ChatListViewModel, currentUser: ChatUser, onChatSelected: @escaping (Chat) -> Void, onNewChatTapped: (() -> Void)? = nil) {
        self.viewModel = viewModel
        self.currentUser = currentUser
        self.onChatSelected = onChatSelected
        self.onNewChatTapped = onNewChatTapped
    }

    public var body: some View {
        VStack(spacing: 0) {
            header
            searchBar
            content
        }
        .background(Self.backgroundColor)
        .task { await viewModel.loadChats() }
        .refreshable { await viewModel.loadChats() }
    }

    private var header: some View {
        HStack(spacing: 12) {
            // Profile avatar (initials)
            InitialAvatarView(initials: initials(for: currentUser.displayName))
                .frame(width: 34, height: 34)

            Text("Chats")
                .font(.system(size: 28, weight: .bold))
                .frame(maxWidth: .infinity, alignment: .leading)

            Button(action: { onNewChatTapped?() }) {
                Image(systemName: "square.and.pencil")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Color.blue)
                    .frame(width: 32, height: 32)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    private var searchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            TextField("Search", text: $searchText)
                .textFieldStyle(.plain)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Self.searchBackgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }

    private var content: some View {
        Group {
            if viewModel.isLoading {
                VStack(spacing: 8) {
                    ProgressView()
                    Text("Loading chats…").foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if filteredChats.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "bubble.left.and.bubble.right")
                        .font(.system(size: 28))
                        .foregroundColor(.secondary)
                    Text("No chats yet")
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(filteredChats) { item in
                        Button(action: { onChatSelected(item.chat) }) {
                            ChatRow(item: item)
                        }
                        .buttonStyle(.plain)
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) { /* TODO delete/archive */ } label: {
                                Label("Delete", systemImage: "trash")
                            }
                            Button { /* TODO mute */ } label: {
                                Label("Mute", systemImage: "bell.slash")
                            }.tint(.gray)
                        }
                    }
                }
                .listStyle(.plain)
            }
        }
    }

    private var filteredChats: [ChatWithPreview] {
        guard !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return viewModel.chats }
        let q = searchText.lowercased()
        return viewModel.chats.filter { $0.title.lowercased().contains(q) || $0.subtitle.lowercased().contains(q) }
    }

    private func initials(for name: String) -> String {
        let parts = name.split(separator: " ")
        let first = parts.first?.first.map(String.init) ?? "?"
        let second = parts.dropFirst().first?.first.map(String.init) ?? ""
        return (first + second).uppercased()
    }
}

// MARK: - Row
private struct ChatRow: View {
    let item: ChatWithPreview

    var body: some View {
        HStack(spacing: 12) {
            InitialAvatarView(initials: avatarInitials)
                .frame(width: 52, height: 52)

            VStack(alignment: .leading, spacing: 2) {
                HStack(alignment: .firstTextBaseline) {
                    Text(item.title)
                        .font(.system(size: 17, weight: item.unreadCount > 0 ? .semibold : .regular))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    Spacer()
                    Text(timeText)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                HStack(spacing: 6) {
                    Text(item.subtitle)
                        .font(.system(size: 14))
                        .foregroundColor(item.unreadCount > 0 ? .primary : .secondary)
                        .lineLimit(1)
                    Spacer()
                    if item.unreadCount > 0 {
                        Text("\(item.unreadCount)")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(Color.blue))
                    }
                }
            }
        }
        .contentShape(Rectangle())
        .padding(.horizontal, 4)
        .padding(.vertical, 6)
    }

    private var avatarInitials: String {
        // Fallback to first two chars of title for demo purposes
        let s = item.title.trimmingCharacters(in: .whitespaces)
        let first = s.first.map { String($0) } ?? "C"
        let second = s.dropFirst().first.map { String($0) } ?? ""
        return (first + second).uppercased()
    }

    private var timeText: String {
        let date = item.timestamp
        let cal = Calendar.current
        if cal.isDateInToday(date) {
            let f = DateFormatter()
            f.dateFormat = "h:mm a"
            return f.string(from: date)
        } else if cal.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            let f = DateFormatter()
            f.dateFormat = "MMM d"
            return f.string(from: date)
        }
    }
}

// MARK: - Avatar
private struct InitialAvatarView: View {
    let initials: String

    var body: some View {
        ZStack {
            Circle().fill(LinearGradient(colors: [Color.blue, Color.purple], startPoint: .topLeading, endPoint: .bottomTrailing))
            Text(initials)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
        }
    }
}

// MARK: - Platform Colors
private extension ChatListView {
    static var backgroundColor: Color {
        #if os(iOS)
        return Color(UIColor.systemBackground)
        #elseif os(macOS)
        return Color(NSColor.windowBackgroundColor)
        #else
        return Color.white
        #endif
    }

    static var searchBackgroundColor: Color {
        #if os(iOS)
        return Color(UIColor.secondarySystemBackground)
        #elseif os(macOS)
        return Color(NSColor.controlBackgroundColor)
        #else
        return Color.gray.opacity(0.12)
        #endif
    }
}
