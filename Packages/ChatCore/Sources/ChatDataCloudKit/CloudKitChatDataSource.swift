import Foundation
import ChatDomain
#if canImport(CloudKit)
import CloudKit

public final class CloudKitChatDataSource: ChatDataSource {
    private let db: CKDatabase

    public init(containerID: String? = nil) {
        let container = containerID != nil ? CKContainer(identifier: containerID!) : CKContainer.default()
        self.db = container.privateCloudDatabase
    }

    public func createChat(members: [ChatUser]) async throws -> Chat {
        let chat = Chat(memberIds: members.map { $0.id })
        let rec = CKRecord(recordType: "Chat", recordID: .init(recordName: chat.id))
        rec["id"] = chat.id as CKRecordValue
        rec["createdAt"] = chat.createdAt as CKRecordValue
        rec["memberIds"] = members.map { $0.id } as CKRecordValue
        _ = try await db.save(rec)
        return chat
    }

    public func getAllChats() async throws -> [Chat] {
        let pred = NSPredicate(value: true) // Optional: filter by current user membership
        let q = CKQuery(recordType: "Chat", predicate: pred)
        q.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
        var results: [Chat] = []
        let (match, _) = try await db.records(matching: q)
        for (_, res) in match {
            if case .success(let rec) = res {
                results.append(recordToChat(rec))
            }
        }
        return results
    }

    public func getLatestMessage(chatId: String) async throws -> Message? {
        let pred = NSPredicate(format: "chatId == %@", chatId)
        let q = CKQuery(recordType: "Message", predicate: pred)
        q.sortDescriptors = [NSSortDescriptor(key: "sentAt", ascending: false)]
        let (match, _) = try await db.records(matching: q, desiredKeys: nil, resultsLimit: 1)
        guard let (_, res) = match.first, case .success(let rec) = res else { return nil }
        return recordToMessage(rec)
    }

    public func messagesStream(chatId: String) -> AsyncThrowingStream<[Message], Error> {
        AsyncThrowingStream { continuation in
            Task { [db] in
                do {
                    var lastSnapshot: [Message] = []
                    while !Task.isCancelled {
                        let current = try await self.fetchMessages(chatId: chatId)
                        if current != lastSnapshot { continuation.yield(current); lastSnapshot = current }
                        try await Task.sleep(nanoseconds: 1_500_000_000) // 1.5s poll for dev
                    }
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }

    public func send(message: Message) async throws {
        let rec = CKRecord(recordType: "Message", recordID: .init(recordName: message.id))
        rec["id"] = message.id as CKRecordValue
        rec["chatId"] = message.chatId as CKRecordValue
        rec["senderId"] = message.senderId as CKRecordValue
        rec["sentAt"] = message.sentAt as CKRecordValue
        rec["kind"] = message.kind.rawValue as CKRecordValue
        if let t = message.text { rec["text"] = t as CKRecordValue }
        _ = try await db.save(rec)
    }

    private func fetchMessages(chatId: String) async throws -> [Message] {
        let pred = NSPredicate(format: "chatId == %@", chatId)
        let q = CKQuery(recordType: "Message", predicate: pred)
        q.sortDescriptors = [NSSortDescriptor(key: "sentAt", ascending: true)]
        let (match, _) = try await db.records(matching: q)
        var msgs: [Message] = []
        for (_, res) in match {
            if case .success(let rec) = res, let m = recordToMessage(rec) { msgs.append(m) }
        }
        return msgs
    }

    private func recordToChat(_ rec: CKRecord) -> Chat {
        let id = rec["id"] as? String ?? rec.recordID.recordName
        let createdAt = rec["createdAt"] as? Date ?? Date()
        let memberIds = rec["memberIds"] as? [String] ?? []
        return Chat(id: id, memberIds: memberIds, createdAt: createdAt)
    }

    private func recordToMessage(_ rec: CKRecord) -> Message? {
        let id = rec["id"] as? String ?? rec.recordID.recordName
        guard let chatId = rec["chatId"] as? String,
              let senderId = rec["senderId"] as? String,
              let sentAt = rec["sentAt"] as? Date else { return nil }
        let kindRaw = rec["kind"] as? String ?? Message.Kind.text.rawValue
        let kind = Message.Kind(rawValue: kindRaw) ?? .text
        let text = rec["text"] as? String
        return Message(id: id, chatId: chatId, senderId: senderId, sentAt: sentAt, kind: kind, text: text)
    }
}
#endif

