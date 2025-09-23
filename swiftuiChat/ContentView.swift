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

struct ContentView: View {
    @StateObject private var vm: ChatViewModel
    private let currentUser = ChatUser(id: "me", displayName: "Me")

    init() {
        let repo = InMemoryChatRepository()
        let container = ChatContainer(repo: repo)
        // Create a demo chat synchronously via Task to avoid async init
        var createdChatId = "demo"
        let semaphore = DispatchSemaphore(value: 0)
        Task {
            let chat = try? await container.createChat(members: [currentUser])
            createdChatId = chat?.id ?? createdChatId
            semaphore.signal()
        }
        semaphore.wait()
        _vm = StateObject(wrappedValue: ChatViewModel(
            chatId: createdChatId,
            currentUser: currentUser,
            observeMessages: container.observeMessages,
            sendMessage: container.sendMessage
        ))
    }

    var body: some View {
        ChatView(viewModel: vm, currentUserId: currentUser.id)
    }
}

#Preview {
    ContentView()
}
