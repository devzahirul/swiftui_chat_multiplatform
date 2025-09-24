import Foundation
import ChatDomain

public struct ChatEnvironment {
    public let chat: ChatContainer
    public let presence: PresenceSupport?

    public struct PresenceSupport {
        public let observePresence: ObservePresenceUseCase
        public let updatePresence: UpdatePresenceUseCase
        public let observeTyping: ObserveTypingUseCase
        public let setTyping: SetTypingUseCase
    }
}

public enum ChatResolver {
    public static func makeEnvironment(repo: ChatRepository,
                                       presenceRepo: PresenceRepository? = nil,
                                       typingRepo: TypingRepository? = nil) -> ChatEnvironment {
        let chat = ChatContainer(repo: repo)
        var presence: ChatEnvironment.PresenceSupport?
        if let pr = presenceRepo, let tr = typingRepo {
            presence = .init(
                observePresence: .init(repo: pr),
                updatePresence: .init(repo: pr),
                observeTyping: .init(repo: tr),
                setTyping: .init(repo: tr)
            )
        }
        return .init(chat: chat, presence: presence)
    }
}

