import Foundation

public struct ChatUser: Identifiable, Equatable, Hashable, Codable {
    public let id: String
    public var displayName: String
    public var avatarURL: URL?

    public init(id: String, displayName: String, avatarURL: URL? = nil) {
        self.id = id
        self.displayName = displayName
        self.avatarURL = avatarURL
    }
}

public struct Message: Identifiable, Equatable, Hashable, Codable {
    public enum Kind: String, Codable {
        case text
        // Future: image, audio, video, file, system
    }

    public let id: String
    public let chatId: String
    public let senderId: String
    public var sentAt: Date
    public var kind: Kind
    public var text: String?

    public init(id: String = UUID().uuidString,
                chatId: String,
                senderId: String,
                sentAt: Date = .init(),
                kind: Kind = .text,
                text: String? = nil) {
        self.id = id
        self.chatId = chatId
        self.senderId = senderId
        self.sentAt = sentAt
        self.kind = kind
        self.text = text
    }
}

public struct Chat: Identifiable, Equatable, Hashable, Codable {
    public let id: String
    public var memberIds: [String]
    public var createdAt: Date

    public init(id: String = UUID().uuidString, memberIds: [String], createdAt: Date = .init()) {
        self.id = id
        self.memberIds = memberIds
        self.createdAt = createdAt
    }
}

// MARK: - Realtime Events (for presence/typing extensibility)

public struct TypingIndicator: Equatable, Sendable, Codable {
    public let chatId: String
    public let userId: String
    public let isTyping: Bool
    public init(chatId: String, userId: String, isTyping: Bool) {
        self.chatId = chatId
        self.userId = userId
        self.isTyping = isTyping
    }
}

public struct Presence: Equatable, Sendable, Codable {
    public let userId: String
    public let isOnline: Bool
    public init(userId: String, isOnline: Bool) {
        self.userId = userId
        self.isOnline = isOnline
    }
}

public enum ChatEvent: Equatable, Sendable {
    case message(Message)
    case typing(TypingIndicator)
    case presence(Presence)
}
