//
//  DI.swift
//  swiftuiChat
//
//  Sets up dependency graph using SwiftHilt's global DSL.
//

import Foundation
import SwiftHilt
import ChatDomain

#if canImport(ChatDataFirebase)
import ChatDataFirebase
#endif

/// Configure dependencies for the chat app using SwiftHilt's global API.
/// By default uses InMemoryChatRepository for all platforms.
/// You can switch to Firestore on iOS/macOS by linking ChatDataFirebase and
/// calling ChatFirebaseDIModule.register(into:) after `useContainer`.
func loadChatDependencies() {
    // Repository binding
    install {
        provide(ChatRepository.self, lifetime: .singleton) { _ in
            // Toggle via env var if needed (e.g., UITEST_INMEMORY or CHAT_INMEMORY)
            if ProcessInfo.processInfo.environment["CHAT_INMEMORY"] == "1" {
                return InMemoryChatRepository() as ChatRepository
            }
            #if canImport(ChatDataFirebase)
            // If you prefer Firestore by default, comment the next line
            return InMemoryChatRepository() as ChatRepository
            // Alternatively, register Firestore repo below from app entry point:
            // ChatFirebaseDIModule.register(into: defaultContainer)
            #else
            return InMemoryChatRepository() as ChatRepository
            #endif
        }
    }

    // Use cases
    register(ObserveMessagesUseCase.self, lifetime: .transient) { r in
        ObserveMessagesUseCase(repo: r.resolve())
    }
    register(SendMessageUseCase.self, lifetime: .transient) { r in
        SendMessageUseCase(repo: r.resolve())
    }
    register(CreateChatUseCase.self, lifetime: .transient) { r in
        CreateChatUseCase(repo: r.resolve())
    }
}
