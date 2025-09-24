import Foundation
import ChatDomain

#if canImport(SwiftData)
import SwiftData

@available(iOS 17, macOS 14, watchOS 10, *)
@Model
final class ChatModel {
    @Attribute(.unique) var id: String
    var createdAt: Date
    @Relationship(deleteRule: .cascade) var members: [ChatMemberModel]

    init(id: String, createdAt: Date, members: [ChatMemberModel] = []) {
        self.id = id
        self.createdAt = createdAt
        self.members = members
    }
}

@available(iOS 17, macOS 14, watchOS 10, *)
@Model
final class ChatMemberModel {
    @Attribute(.unique) var id: String
    var userId: String
    @Relationship(inverse: \ChatModel.members) var chat: ChatModel?

    init(id: String, userId: String, chat: ChatModel? = nil) {
        self.id = id
        self.userId = userId
        self.chat = chat
    }
}

@available(iOS 17, macOS 14, watchOS 10, *)
@Model
final class MessageModel {
    @Attribute(.unique) var id: String
    var chatId: String
    var senderId: String
    var sentAt: Date
    var kindRaw: String
    var text: String?

    init(id: String, chatId: String, senderId: String, sentAt: Date, kindRaw: String, text: String?) {
        self.id = id
        self.chatId = chatId
        self.senderId = senderId
        self.sentAt = sentAt
        self.kindRaw = kindRaw
        self.text = text
    }
}

@available(iOS 17, macOS 14, watchOS 10, *)
extension ChatModel {
    static func make(from chat: Chat) -> ChatModel {
        let model = ChatModel(id: chat.id, createdAt: chat.createdAt)
        // Attach member rows
        model.members = chat.memberIds.map { uid in
            ChatMemberModel(id: "\(chat.id):\(uid)", userId: uid, chat: model)
        }
        return model
    }

    var domain: Chat { Chat(id: id, memberIds: members.map { $0.userId }, createdAt: createdAt) }
}

@available(iOS 17, macOS 14, watchOS 10, *)
extension MessageModel {
    convenience init(from message: Message) {
        self.init(id: message.id, chatId: message.chatId, senderId: message.senderId, sentAt: message.sentAt, kindRaw: message.kind.rawValue, text: message.text)
    }

    var domain: Message {
        var kind: Message.Kind = .text
        if let k = Message.Kind(rawValue: kindRaw) { kind = k }
        return Message(id: id, chatId: chatId, senderId: senderId, sentAt: sentAt, kind: kind, text: text)
    }
}

// Factory to create a container without exposing internal model types to clients.
public enum SwiftDataSupport {
    @available(iOS 17, macOS 14, watchOS 10, *)
    public static func makeContainer(inMemory: Bool = true) throws -> ModelContainer {
        let config = ModelConfiguration(isStoredInMemoryOnly: inMemory)
        // Note: pass varargs, not an array
        return try ModelContainer(for: ChatModel.self, ChatMemberModel.self, MessageModel.self, configurations: config)
    }
}

@available(iOS 17, macOS 14, watchOS 10, *)
public final class SwiftDataChatDataSource: ChatDataSource {
    private let container: ModelContainer

    private struct Listener {
        let id: UUID
        let continuation: AsyncThrowingStream<[Message], Error>.Continuation
    }
    private var listeners: [String: [Listener]] = [:]
    private let lock = NSLock()

    public init(container: ModelContainer) {
        self.container = container
    }

    public func createChat(members: [ChatUser]) async throws -> Chat {
        let chat = Chat(memberIds: members.map { $0.id })
        try await MainActor.run {
            let ctx = container.mainContext
            let model = ChatModel.make(from: chat)
            ctx.insert(model)
            try ctx.save()
        }
        return chat
    }

    public func getAllChats() async throws -> [Chat] {
        try await MainActor.run {
            var descriptor = FetchDescriptor<ChatModel>()
            descriptor.sortBy = [SortDescriptor(\.createdAt, order: .reverse)]
            let models = try container.mainContext.fetch(descriptor)
            return models.map { $0.domain }
        }
    }

    public func getLatestMessage(chatId: String) async throws -> Message? {
        try await MainActor.run {
            var descriptor = FetchDescriptor<MessageModel>(predicate: #Predicate { $0.chatId == chatId })
            descriptor.sortBy = [SortDescriptor(\.sentAt, order: .reverse)]
            descriptor.fetchLimit = 1
            return try container.mainContext.fetch(descriptor).first?.domain
        }
    }

    public func messagesStream(chatId: String) -> AsyncThrowingStream<[Message], Error> {
        let id = UUID()
        return AsyncThrowingStream { continuation in
            // Register listener and emit current snapshot
            self.lock.lock()
            var arr = self.listeners[chatId] ?? []
            arr.append(Listener(id: id, continuation: continuation))
            self.listeners[chatId] = arr
            self.lock.unlock()

            Task { [weak self] in
                guard let self else { return }
                let current = (try? await self.fetchMessages(chatId: chatId)) ?? []
                continuation.yield(current)
            }

            continuation.onTermination = { [weak self] _ in
                guard let self else { return }
                self.lock.lock(); defer { self.lock.unlock() }
                self.listeners[chatId]?.removeAll { $0.id == id }
            }
        }
    }

    public func send(message: Message) async throws {
        // Ensure chat exists and insert on main actor
        try await MainActor.run {
            let ctx = container.mainContext
            let chatExists = try ctx.fetchCount(FetchDescriptor<ChatModel>(predicate: #Predicate { $0.id == message.chatId })) > 0
            if !chatExists { throw ChatError.chatNotFound }
            let model = MessageModel(from: message)
            ctx.insert(model)
            try ctx.save()
        }

        // Notify listeners
        let snapshot = (try? await fetchMessages(chatId: message.chatId)) ?? []
        let listeners = withLockedListeners(for: message.chatId)
        listeners.forEach { $0.continuation.yield(snapshot) }
    }

    private func withLockedListeners(for chatId: String) -> [Listener] {
        lock.lock(); defer { lock.unlock() }
        return listeners[chatId] ?? []
    }

    private func fetchMessages(chatId: String) async throws -> [Message] {
        try await MainActor.run {
            var descriptor = FetchDescriptor<MessageModel>(predicate: #Predicate { $0.chatId == chatId })
            descriptor.sortBy = [SortDescriptor(\.sentAt, order: .forward)]
            let models = try container.mainContext.fetch(descriptor)
            return models.map { $0.domain }
        }
    }
}

#endif
