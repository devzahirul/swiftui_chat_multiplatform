import Foundation
import Security
import ChatDomain
import LoginDomain

final class KeychainHelper {
    static func save(_ data: Data, service: String, account: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: data
        ]
        SecItemDelete(query as CFDictionary)
        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }

    static func load(service: String, account: String) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess else { return nil }
        return item as? Data
    }

    static func delete(service: String, account: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        SecItemDelete(query as CFDictionary)
    }
}

public final class KeychainAuthRepository: AuthRepository {
    private let service = "com.lynkto.swiftuiChat.auth"
    private let account = "appleUserId"
    private let nameKey = "displayName"
    private let emailKey = "email"

    public init() {}

    public func load() -> (user: ChatUser?, email: String?) {
        if let data = KeychainHelper.load(service: service, account: account),
           let userId = String(data: data, encoding: .utf8) {
            let name = UserDefaults.standard.string(forKey: nameKey) ?? "Me"
            let user = ChatUser(id: userId, displayName: name)
            let email = UserDefaults.standard.string(forKey: emailKey)
            return (user, email)
        }
        return (nil, nil)
    }

    public func signIn(userId: String, fullName: PersonNameComponents?, email: String?) {
        _ = KeychainHelper.save(Data(userId.utf8), service: service, account: account)
        let displayName: String
        if let fullName {
            displayName = PersonNameComponentsFormatter().string(from: fullName).trimmingCharacters(in: .whitespacesAndNewlines)
        } else {
            displayName = "Me"
        }
        UserDefaults.standard.set(displayName, forKey: nameKey)
        if let email { UserDefaults.standard.set(email, forKey: emailKey) }
    }

    public func signOut() {
        KeychainHelper.delete(service: service, account: account)
        UserDefaults.standard.removeObject(forKey: nameKey)
        UserDefaults.standard.removeObject(forKey: emailKey)
    }

    public func updateDisplayName(_ newName: String) -> ChatUser? {
        let trimmed = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        let name = trimmed.isEmpty ? "Me" : trimmed
        UserDefaults.standard.set(name, forKey: nameKey)
        let current = load()
        if let user = current.user {
            return ChatUser(id: user.id, displayName: name)
        }
        return nil
    }
}
