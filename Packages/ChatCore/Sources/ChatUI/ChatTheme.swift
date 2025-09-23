import SwiftUI

public struct ChatTheme: Equatable {
    public var background: Color
    public var incoming: Color
    public var outgoing: Color
    public var text: Color
    public var composerBackground: Color

    public init(background: Color = Color(UIColor.systemBackground),
                incoming: Color = Color.gray.opacity(0.2),
                outgoing: Color = Color.accentColor.opacity(0.2),
                text: Color = .primary,
                composerBackground: Color = Color(UIColor.secondarySystemBackground)) {
        self.background = background
        self.incoming = incoming
        self.outgoing = outgoing
        self.text = text
        self.composerBackground = composerBackground
    }
}

public struct ChatThemeKey: EnvironmentKey {
    public static let defaultValue = ChatTheme()
}

public extension EnvironmentValues {
    var chatTheme: ChatTheme {
        get { self[ChatThemeKey.self] }
        set { self[ChatThemeKey.self] = newValue }
    }
}
