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
    private let container: Container
    @State private var chatId: String?

    init() {
        let c = Container()
        useContainer(c)
        loadChatDependencies()
        self.container = c
    }

    var body: some View {
        Group {
            if let id = chatId {
                ChatScreen(chatId: id, container: container, currentUser: currentUser)
            } else {
                VStack(spacing: 12) {
                    ProgressView()
                    Text("Preparing chat…")
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .onAppear {
            if chatId == nil {
                Task {
                    let create: CreateChatUseCase = container.resolve()
                    if let chat = try? await create(members: [currentUser]) {
                        chatId = chat.id
                    }
                }
            }
        }
    }
}

private struct ChatScreen: View {
    let chatId: String
    let container: Container
    let currentUser: ChatUser
    @StateObject private var vm: ChatViewModel

    init(chatId: String, container: ChatContainer, currentUser: ChatUser) {
        self.chatId = chatId
        self.container = container
        self.currentUser = currentUser
        let observe: ObserveMessagesUseCase = container.resolve()
        let send: SendMessageUseCase = container.resolve()
        _vm = StateObject(wrappedValue: ChatViewModel(chatId: chatId, currentUser: currentUser, observeMessages: observe, sendMessage: send))
    }

    var body: some View {
        ChatView(viewModel: vm, currentUserId: currentUser.id)
            .onAppear { vm.start() }
    }
}

#Preview {
    ContentView()
}
