import Foundation
import ChatDomain

public protocol ChatDataPlugin {
    static func makeRepository() -> ChatRepository
}

public enum ChatCoreRegistry {
    public static var makeRepository: (() -> ChatRepository)?
    public static var makePresenceRepository: (() -> PresenceRepository)?
    public static var makeTypingRepository: (() -> TypingRepository)?
}
