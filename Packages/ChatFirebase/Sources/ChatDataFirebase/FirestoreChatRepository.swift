import Foundation
import FirebaseCore
import FirebaseFirestore
import ChatDomain
import SwiftHilt

public final class FirestoreChatRepository: ChatRepository {
    private let db: Firestore

    public init(app: FirebaseApp? = FirebaseApp.app()) {
        if let app { self.db = Firestore.firestore(app: app) }
        else { self.db = Firestore.firestore() }
    }

    public func createChat(members: [ChatUser]) async throws -> Chat {
        let chat = Chat(memberIds: members.map { $0.id })
        let data: [String: Any] = [
            "memberIds": chat.memberIds,
            "createdAt": Timestamp(date: chat.createdAt)
        ]
        try await db.collection("chats").document(chat.id).setData(data)
        return chat
    }

    public func messagesStream(chatId: String) -> AsyncThrowingStream<[Message], Error> {
        AsyncThrowingStream { continuation in
            let listener = db.collection("chats").document(chatId).collection("messages")
                .order(by: "sentAt")
                .addSnapshotListener { snapshot, error in
                    if let error { continuation.finish(throwing: error); return }
                    guard let docs = snapshot?.documents else { return }
                    let list: [Message] = docs.compactMap { doc in
                        let data = doc.data()
                        let id = doc.documentID
                        guard let senderId = data["senderId"] as? String else { return nil }
                        let text = data["text"] as? String
                        let ts = data["sentAt"] as? Timestamp ?? Timestamp(date: .init())
                        return Message(id: id, chatId: chatId, senderId: senderId, sentAt: ts.dateValue(), kind: .text, text: text)
                    }
                    continuation.yield(list)
                }
            continuation.onTermination = { _ in listener.remove() }
        }
    }

    public func send(message: Message) async throws {
        let data: [String: Any] = [
            "senderId": message.senderId,
            "text": message.text ?? "",
            "kind": message.kind.rawValue,
            "sentAt": Timestamp(date: message.sentAt)
        ]
        try await db.collection("chats").document(message.chatId)
            .collection("messages").document(message.id).setData(data)
    }
}

public enum ChatFirebaseDIModule {
    // Registers FirestoreChatRepository into the container for platforms supporting Firebase
    public static func register(into c: Container) {
        c.register(ChatRepository.self, lifetime: .scoped) { _ in
            FirestoreChatRepository()
        }
    }
}
