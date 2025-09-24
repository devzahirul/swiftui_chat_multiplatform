import SwiftUI
import ChatDomain
import LoginPresentation
#if canImport(AuthenticationServices)
import AuthenticationServices
#endif

public struct LoginView: View {
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject var auth: AuthStore
    @State private var error: String?

    public init() {}

    public var body: some View {
        VStack(spacing: 24) {
            Spacer()
            VStack(spacing: 8) {
                Text("Welcome to swiftuiChat")
                    .font(.largeTitle).bold()
                Text("Sign in with Apple to continue")
                    .foregroundColor(.secondary)
            }

            #if canImport(AuthenticationServices)
            SignInWithAppleButton(.signIn, onRequest: configure, onCompletion: handle)
                .signInWithAppleButtonStyle(colorScheme == .dark ? .white : .black)
                .frame(height: 48)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            #else
            Text("Sign in with Apple isn't available on this platform.")
                .font(.footnote)
                .foregroundColor(.secondary)
            #endif

            if let error { Text(error).foregroundColor(.red).font(.footnote) }
            Spacer()
        }
        .padding()
    }

    #if canImport(AuthenticationServices)
    private func configure(_ request: ASAuthorizationAppleIDRequest) {
        request.requestedScopes = [.fullName, .email]
    }

    private func handle(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authResult):
            if let credential = authResult.credential as? ASAuthorizationAppleIDCredential {
                let userId = credential.user
                auth.signIn(userId: userId, fullName: credential.fullName, email: credential.email)
            } else {
                error = "Unsupported credential"
            }
        case .failure(let err):
            error = err.localizedDescription
        }
    }
    #endif
}
