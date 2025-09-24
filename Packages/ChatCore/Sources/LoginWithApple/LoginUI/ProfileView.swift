import SwiftUI
import ChatDomain
import LoginPresentation

public struct ProfileView: View {
    @EnvironmentObject private var auth: AuthStore
    @Environment(\.dismiss) private var dismiss
    @State private var name: String = ""
    @State private var showCopiedAlert = false
    @State private var copiedLabel = ""

    public init() {}

    public var body: some View {
        NavigationStack {
            Form {
                if let user = auth.currentUser {
                    Section {
                        VStack(spacing: 12) {
                            avatarView(for: user.displayName)
                                .frame(width: 72, height: 72)
                                .padding(.top, 8)
                            Text(user.displayName)
                                .font(.title3).bold()
                        }
                        .frame(maxWidth: .infinity)
                        .listRowBackground(Color.clear)
                        .multilineTextAlignment(.center)
                    }

                    Section(header: Text("Account")) {
                        HStack {
                            Text("User ID")
                            Spacer()
                            HStack(spacing: 8) {
                                Text(user.id)
                                    .font(.footnote)
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                                    .truncationMode(.middle)
                                Button {
                                    copy(user.id, label: "User ID")
                                } label: {
                                    Image(systemName: "doc.on.doc")
                                }
                                .buttonStyle(.plain)
                                .help("Copy User ID")
                            }
                        }
                        if let email = auth.email {
                            HStack {
                                Text("Email")
                                Spacer()
                                HStack(spacing: 8) {
                                    Text(email)
                                        .font(.footnote)
                                        .foregroundColor(.secondary)
                                        .lineLimit(1)
                                        .truncationMode(.middle)
                                    Button {
                                        copy(email, label: "Email")
                                    } label: {
                                        Image(systemName: "doc.on.doc")
                                    }
                                    .buttonStyle(.plain)
                                    .help("Copy Email")
                                }
                            }
                        }
                        TextField("Display name", text: $name)
                            .onSubmit(save)
                    }

                    Section {
                        Button(role: .destructive) {
                            auth.signOut()
                            dismiss()
                        } label: {
                            Text("Sign Out")
                        }
                    }
                } else {
                    Text("Not signed in")
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Profile")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save)
                        .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .onAppear {
                name = auth.currentUser?.displayName ?? ""
            }
        }
        .alert("Copied", isPresented: $showCopiedAlert) {
        } message: {
            Text("\(copiedLabel) copied to clipboard")
        }
    }

    private func save() {
        auth.updateDisplayName(name)
        dismiss()
    }

    private func copy(_ text: String, label: String) {
        Clipboard.copy(text)
        copiedLabel = label
        showCopiedAlert = true
    }

    private func avatarView(for name: String) -> some View {
        let initials = initials(from: name)
        return ZStack {
            Circle()
                .fill(LinearGradient(
                    colors: [Color.blue, Color.purple],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
            Text(initials)
                .font(.system(size: 28, weight: .semibold))
                .foregroundColor(.white)
        }
    }

    private func initials(from name: String) -> String {
        let parts = name.split(separator: " ")
        let first = parts.first?.first.map(String.init) ?? "?"
        let second = parts.dropFirst().first?.first.map(String.init) ?? ""
        return (first + second).uppercased()
    }
}
