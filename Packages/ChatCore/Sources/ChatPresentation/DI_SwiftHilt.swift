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

    // Optional presence/typing modules (apps register repos themselves)
    public static func registerPresence(into c: Container, presenceRepo: PresenceRepository) {
        c.provide(PresenceRepository.self, lifetime: .singleton) { _ in presenceRepo }
        c.register(ObservePresenceUseCase.self, lifetime: .transient) { r in
            ObservePresenceUseCase(repo: r.resolve(PresenceRepository.self))
        }
        c.register(UpdatePresenceUseCase.self, lifetime: .transient) { r in
            UpdatePresenceUseCase(repo: r.resolve(PresenceRepository.self))
        }
    }

    public static func registerTyping(into c: Container, typingRepo: TypingRepository) {
        c.provide(TypingRepository.self, lifetime: .singleton) { _ in typingRepo }
        c.register(ObserveTypingUseCase.self, lifetime: .transient) { r in
            ObserveTypingUseCase(repo: r.resolve(TypingRepository.self))
        }
        c.register(SetTypingUseCase.self, lifetime: .transient) { r in
            SetTypingUseCase(repo: r.resolve(TypingRepository.self))
        }
    }
}
#endif
