//
//  ContentView.swift
//  swiftuiChat
//
//  Created by lynkto_1 on 9/23/25.
//

import SwiftUI
import ChatDomain
import ChatPresentation
import ChatUI
import SwiftHilt
import LoginWithApple

struct ContentView: View {
    @StateObject private var auth = AuthStore(repo: KeychainAuthRepository())
    @State private var selectedChat: Chat?
    @State private var navigationPath = NavigationPath()
    @State private var showingProfile = false

    init() {
        let c = Container()
        useContainer(c)
        loadChatDependencies()
    }

    var body: some View {
        Group {
            if let user = auth.currentUser {
                NavigationStack(path: $navigationPath) {
                    ChatListScreen(currentUser: user, onAvatarTapped: { showingProfile = true }) { chat in
                        selectedChat = chat
                        navigationPath.append(chat.id)
                    }
                    .navigationDestination(for: String.self) { chatId in
                        if let chat = selectedChat, chat.id == chatId {
                            CustomChatScreen(chat: chat, currentUser: user)
#if canImport(UIKit)
                                .navigationBarTitleDisplayMode(.inline)
#endif
                        }
                    }
                }
                .sheet(isPresented: $showingProfile) {
                    ProfileView()
                        .environmentObject(auth)
                }
            } else {
                LoginView()
            }
        }
        .environmentObject(auth)
    }

    // Toolbar removed; using inline header button above chat list
}

private struct ChatScreen: View {
    let chatId: String
    let currentUser: ChatUser
    @StateObject private var vm: ChatViewModel

    init(chatId: String, currentUser: ChatUser) {
        self.chatId = chatId
        self.currentUser = currentUser
        let observe: ObserveMessagesUseCase = resolve()
        let send: SendMessageUseCase = resolve()
        _vm = StateObject(wrappedValue: ChatViewModel(chatId: chatId, currentUser: currentUser, observeMessages: observe, sendMessage: send))
    }

    var body: some View {
        ChatView(viewModel: vm, currentUserId: currentUser.id)
            .onAppear { vm.start() }
    }
}

private struct ChatListScreen: View {
    let currentUser: ChatUser
    let onChatSelected: (Chat) -> Void
    let onAvatarTapped: () -> Void
    @StateObject private var viewModel: ChatPresentation.ChatListViewModel

    init(currentUser: ChatUser, onAvatarTapped: @escaping () -> Void, onChatSelected: @escaping (Chat) -> Void) {
        self.currentUser = currentUser
        self.onChatSelected = onChatSelected
        self.onAvatarTapped = onAvatarTapped
        let getAllChats: GetAllChatsUseCase = resolve()
        let getLatestMessage: GetLatestMessageUseCase = resolve()
        _viewModel = StateObject(wrappedValue: ChatPresentation.ChatListViewModel(getAllChats: getAllChats, getLatestMessage: getLatestMessage))
    }

    var body: some View {
        ChatUI.ChatListView(
            viewModel: viewModel,
            currentUser: currentUser,
            onChatSelected: onChatSelected,
            onNewChatTapped: {
                Task {
                    let create: CreateChatUseCase = resolve()
                    if let newChat = try? await create(members: [currentUser]) {
                        onChatSelected(newChat)
                        await viewModel.loadChats()
                    }
                }
            },
            onHeaderAvatarTapped: onAvatarTapped
        )
        .navigationTitle("")
#if canImport(UIKit)
        .navigationBarHidden(true)
#endif
    }
}

#Preview {
    ContentView()
}

// Header icon handled by ChatUI.MessengerChatListView
