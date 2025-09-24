//
//  DI.swift
//  swiftuiChat
//
//  Sets up dependency graph using SwiftHilt's global DSL.
//

import Foundation
import SwiftHilt
import ChatDomain
import ChatData
#if canImport(SwiftData)
import SwiftData
#endif
// CloudKit data source (optional)
#if canImport(ChatDataCloudKit)
import ChatDataCloudKit
#endif

#if canImport(ChatDataFirebase)
import ChatDataFirebase
#endif

/// Configure dependencies for the chat app using SwiftHilt's global API.
/// By default uses InMemoryChatRepository for all platforms.
/// You can switch to Firestore on iOS/macOS by linking ChatDataFirebase and
/// calling ChatFirebaseDIModule.register(into:) after `useContainer`.
@MainActor
func loadChatDependencies() {
    // Repository binding
    install {
        provide(ChatRepository.self, lifetime: .singleton) { _ in
            // Explicit override flags first
            if ProcessInfo.processInfo.environment["CHAT_INMEMORY"] == "1" {
                return ChatRepositoryImpl(dataSource: InMemoryChatDataSource()) as ChatRepository
            }
            #if canImport(ChatDataCloudKit)
            if ProcessInfo.processInfo.environment["CHAT_CLOUDKIT"] == "1" {
                let containerID = ProcessInfo.processInfo.environment["CK_CONTAINER"]
                return ChatRepositoryImpl(dataSource: CloudKitChatDataSource(containerID: containerID)) as ChatRepository
            }
            #endif
            #if canImport(ChatDataFirebase)
            if ProcessInfo.processInfo.environment["CHAT_FIREBASE"] == "1" {
                // ChatFirebaseDIModule.register(into: defaultContainer) could be used instead
                return ChatRepositoryImpl(dataSource: InMemoryChatDataSource()) as ChatRepository
            }
            #endif
            // Default to SwiftData (persistent) when available
            #if canImport(SwiftData)
            if #available(iOS 17, macOS 14, watchOS 10, *) {
                let inMemoryStore = ProcessInfo.processInfo.environment["CHAT_SWIFTDATA_INMEMORY"] == "1"
                if let container = try? SwiftDataSupport.makeContainer(inMemory: inMemoryStore) {
                    return ChatRepositoryImpl(dataSource: SwiftDataChatDataSource(container: container)) as ChatRepository
                }
            }
            #endif
            // Fallback
            return ChatRepositoryImpl(dataSource: InMemoryChatDataSource()) as ChatRepository
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
    register(GetAllChatsUseCase.self, lifetime: .transient) { r in
        GetAllChatsUseCase(repo: r.resolve())
    }
    register(GetLatestMessageUseCase.self, lifetime: .transient) { r in
        GetLatestMessageUseCase(repo: r.resolve())
    }
}
