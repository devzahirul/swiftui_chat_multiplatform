import Foundation
import ChatDomain

public protocol AuthRepository {
    func load() -> (user: ChatUser?, email: String?)
    func signIn(userId: String, fullName: PersonNameComponents?, email: String?)
    func signOut()
    func updateDisplayName(_ newName: String) -> ChatUser?
}
