import Foundation
import ChatDomain
#if canImport(SwiftHilt)
import SwiftHilt

public enum ChatDIModules {
    // Registers default bindings for ChatRepository and UseCases
    public static func registerCore(into c: Container, repoFactory: @escaping (Resolver) -> ChatRepository = { _ in InMemoryChatRepository() }) {
        // Repository binding
        

        // Use cases
        c.register(ObserveMessagesUseCase.self, lifetime: .transient) { r in
            ObserveMessagesUseCase(repo: r.resolve(ChatRepository.self))
        }
        c.register(SendMessageUseCase.self, lifetime: .transient) { r in
            SendMessageUseCase(repo: r.resolve(ChatRepository.self))
        }
        c.register(CreateChatUseCase.self, lifetime: .transient) { r in
            CreateChatUseCase(repo: r.resolve(ChatRepository.self))
        }
    }
}
#endif
