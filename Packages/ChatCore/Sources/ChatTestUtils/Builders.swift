import Foundation
import ChatDomain

public enum Fixtures {
    public static func user(id: String = UUID().uuidString, name: String = "User") -> ChatUser {
        .init(id: id, displayName: name)
    }

    public static func message(chatId: String, senderId: String, text: String = "Hello", date: Date = .init()) -> Message {
        .init(chatId: chatId, senderId: senderId, sentAt: date, kind: .text, text: text)
    }
}
