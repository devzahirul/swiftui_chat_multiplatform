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
