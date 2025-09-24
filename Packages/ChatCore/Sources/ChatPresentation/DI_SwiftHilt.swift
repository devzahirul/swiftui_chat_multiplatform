import Foundation
import ChatDomain
#if canImport(SwiftHilt)
import SwiftHilt

public enum ChatDIModules {
    public static func registerAll(into c: Container, using repoFactory: @escaping () -> ChatRepository) {
        c.provide(ChatRepository.self, lifetime: .singleton) { _ in repoFactory() }
        registerCore(into: c)
    }
    // Registers use cases. Expect ChatRepository to be registered by the app.
    public static func registerCore(into c: Container) {
        c.register(ObserveMessagesUseCase.self, lifetime: .transient) { r in
            ObserveMessagesUseCase(repo: r.resolve(ChatRepository.self))
        }
        c.register(SendMessageUseCase.self, lifetime: .transient) { r in
            SendMessageUseCase(repo: r.resolve(ChatRepository.self))
        }
        c.register(CreateChatUseCase.self, lifetime: .transient) { r in
            CreateChatUseCase(repo: r.resolve(ChatRepository.self))
        }
        c.register(GetAllChatsUseCase.self, lifetime: .transient) { r in
            GetAllChatsUseCase(repo: r.resolve(ChatRepository.self))
        }
        c.register(GetLatestMessageUseCase.self, lifetime: .transient) { r in
            GetLatestMessageUseCase(repo: r.resolve(ChatRepository.self))
        }
    }
}
#endif
