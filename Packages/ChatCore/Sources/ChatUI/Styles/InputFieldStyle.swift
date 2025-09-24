import SwiftUI

public struct ChatInputConfiguration {
    public var text: Binding<String>
    public let placeholder: String
    public let onSend: () -> Void
    public let onTyping: (Bool) -> Void
    public init(text: Binding<String>, placeholder: String = "Message", onSend: @escaping () -> Void, onTyping: @escaping (Bool) -> Void = { _ in }) {
        self.text = text
        self.placeholder = placeholder
        self.onSend = onSend
        self.onTyping = onTyping
    }
}

public protocol InputFieldStyle {
    associatedtype Body: View
    func makeBody(_ configuration: ChatInputConfiguration) -> Body
}

public struct MessengerInputFieldStyle: InputFieldStyle {
    let leading: (() -> AnyView)?
    let trailing: (() -> AnyView)?
    public init(leading: (() -> AnyView)? = nil, trailing: (() -> AnyView)? = nil) {
        self.leading = leading
        self.trailing = trailing
    }
    public func makeBody(_ configuration: ChatInputConfiguration) -> some View {
        MessengerInputField(
            text: configuration.text,
            placeholder: configuration.placeholder,
            onSend: configuration.onSend,
            onTyping: configuration.onTyping,
            leadingAccessory: leading,
            trailingAccessory: trailing
        )
    }
}

