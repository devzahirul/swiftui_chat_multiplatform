import SwiftUI
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

public struct MessengerInputField: View {
    @Binding var text: String
    let placeholder: String
    let onSend: () -> Void
    let onTyping: (Bool) -> Void
    let leadingAccessory: (() -> AnyView)?
    let trailingAccessory: (() -> AnyView)?

    @Environment(\.messengerTheme) private var theme
    @State private var isMultiline = false
    @FocusState private var isFocused: Bool

    public init(
        text: Binding<String>,
        placeholder: String = "Message",
        onSend: @escaping () -> Void,
        onTyping: @escaping (Bool) -> Void = { _ in },
        leadingAccessory: (() -> AnyView)? = nil,
        trailingAccessory: (() -> AnyView)? = nil
    ) {
        self._text = text
        self.placeholder = placeholder
        self.onSend = onSend
        self.onTyping = onTyping
        self.leadingAccessory = leadingAccessory
        self.trailingAccessory = trailingAccessory
    }

    public var body: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(theme.separator)
                .frame(height: 0.5)

            HStack(alignment: .bottom, spacing: 8) {
                if let leadingAccessory { leadingAccessory() }
                else {
                    // Default camera/media button
                    Button(action: {}) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 20))
                            .foregroundColor(theme.outgoing)
                            .frame(width: 32, height: 32)
                    }
                    .buttonStyle(.plain)
                }

                // Text input container
                HStack(alignment: .bottom, spacing: 8) {
                    textInputField

                    // Emoji/Sticker button (when text is empty)
                    if text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Button(action: {}) {
                            Image(systemName: "face.smiling")
                                .font(.system(size: 20))
                                .foregroundColor(theme.outgoing)
                                .frame(width: 32, height: 32)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 18)
                        .fill(Color(red: 245/255, green: 245/255, blue: 247/255))
                )
                .overlay {
                    if isFocused {
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(theme.outgoing.opacity(0.3), lineWidth: 1)
                    }
                }

                if let trailingAccessory { trailingAccessory() }
                else {
                    // Send button (appears when text is not empty)
                    if !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        sendButton
                            .transition(.scale.combined(with: .opacity))
                    }
                }
            }
            .padding(.horizontal, MessengerTheme.Spacing.defaultPadding)
            .padding(.vertical, 8)
        }
        .background(theme.composerBackground)
        .onChange(of: text) { newValue in
            onTyping(!newValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            updateMultilineState()
        }
    }

    private var textInputField: some View {
        ZStack(alignment: .topLeading) {
            if text.isEmpty {
                Text(placeholder)
                    .foregroundColor(.secondary)
                    .padding(.vertical, 8)
                    .padding(.leading, 4)
            }

            TextField("", text: $text, axis: .vertical)
                .focused($isFocused)
                .textFieldStyle(.plain)
                .font(MessengerTheme.Typography.messageText)
                .lineLimit(1...6)
                .padding(.vertical, 8)
                .padding(.leading, 4)
                .onSubmit {
                    if !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        onSend()
                    }
                }
        }
        .frame(minHeight: MessengerTheme.Spacing.inputFieldHeight)
    }

    private var sendButton: some View {
        Button(action: {
            guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
            onSend()
        }) {
            Image(systemName: "arrow.up.circle.fill")
                .font(.system(size: 32))
                .foregroundColor(theme.outgoing)
        }
        .buttonStyle(.plain)
        .scaleEffect(isFocused ? 1.1 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isFocused)
    }

    private func updateMultilineState() {
        withAnimation(.easeInOut(duration: 0.2)) {
            isMultiline = text.contains("\n") || text.count > 50
        }
    }
}

// MARK: - Messenger Input Toolbar
public struct MessengerInputToolbar: View {
    @Binding var text: String
    let onSend: () -> Void
    let onTyping: (Bool) -> Void

    @Environment(\.messengerTheme) private var theme

    public init(
        text: Binding<String>,
        onSend: @escaping () -> Void,
        onTyping: @escaping (Bool) -> Void = { _ in }
    ) {
        self._text = text
        self.onSend = onSend
        self.onTyping = onTyping
    }

    public var body: some View {
        MessengerInputField(
            text: $text,
            onSend: onSend,
            onTyping: onTyping
        )
    }
}

// MARK: - Chat Input Extensions
public extension MessengerInputField {
    static func chatInput(
        text: Binding<String>,
        onSend: @escaping () -> Void
    ) -> some View {
        MessengerInputField(
            text: text,
            placeholder: "Message",
            onSend: onSend
        )
    }
}

// MARK: - Preview Support
#if DEBUG
struct MessengerInputField_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            Spacer()
            MessengerInputField(
                text: .constant(""),
                onSend: {}
            )
        }
        #if canImport(UIKit)
        .background(Color(UIColor.systemBackground))
        #else
        .background(Color(NSColor.controlBackgroundColor))
        #endif
        .environment(\.messengerTheme, MessengerTheme.light)
    }
}
#endif
