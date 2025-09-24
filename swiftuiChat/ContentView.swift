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

struct ContentView: View {
    private let currentUser = ChatUser(id: "me", displayName: "Me")
    @State private var selectedChat: Chat?
    @State private var navigationPath = NavigationPath()

    init() {
        let c = Container()
        useContainer(c)
        loadChatDependencies()
    }

    var body: some View {
        NavigationStack(path: $navigationPath) {
            ChatListScreen(currentUser: currentUser) { chat in
                selectedChat = chat
                navigationPath.append(chat.id)
            }
            .navigationDestination(for: String.self) { chatId in
                if let chat = selectedChat, chat.id == chatId {
                    ChatScreen(chatId: chatId, currentUser: currentUser)
                        .navigationBarTitleDisplayMode(.inline)
                }
            }
        }
    }
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
    @StateObject private var viewModel: ChatPresentation.ChatListViewModel

    init(currentUser: ChatUser, onChatSelected: @escaping (Chat) -> Void) {
        self.currentUser = currentUser
        self.onChatSelected = onChatSelected
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
            }
        )
        .navigationTitle("")
        .navigationBarHidden(true)
    }
}

#Preview {
    ContentView()
}
