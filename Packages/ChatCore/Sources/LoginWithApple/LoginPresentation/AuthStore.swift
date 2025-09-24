import Foundation
import Combine
import ChatDomain
import LoginDomain

public final class AuthStore: ObservableObject {
    @Published public private(set) var currentUser: ChatUser?
    @Published public private(set) var email: String?

    private let repo: AuthRepository

    public init(repo: AuthRepository) {
        self.repo = repo
        load()
    }

    public func load() {
        let data = repo.load()
        currentUser = data.user
        email = data.email
    }

    public func signIn(userId: String, fullName: PersonNameComponents?, email: String?) {
        repo.signIn(userId: userId, fullName: fullName, email: email)
        load()
    }

    public func signOut() {
        repo.signOut()
        currentUser = nil
        email = nil
    }

    public func updateDisplayName(_ newName: String) {
        if let updated = repo.updateDisplayName(newName) {
            currentUser = updated
        }
    }
}
