import Foundation
import ChatDomain

public struct ChatContainer {
    public let observeMessages: ObserveMessagesUseCase
    public let sendMessage: SendMessageUseCase
    public let createChat: CreateChatUseCase

    public init(repo: ChatRepository) {
        self.observeMessages = .init(repo: repo)
        self.sendMessage = .init(repo: repo)
        self.createChat = .init(repo: repo)
    }
}
