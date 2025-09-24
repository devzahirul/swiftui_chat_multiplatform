import SwiftUI
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

public struct ChatTheme: Equatable {
    public var background: Color
    public var incoming: Color
    public var outgoing: Color
    public var text: Color
    public var composerBackground: Color

    // Designated initializer (no default args referencing fileprivate members)
    public init(background: Color,
                incoming: Color,
                outgoing: Color,
                text: Color,
                composerBackground: Color) {
        self.background = background
        self.incoming = incoming
        self.outgoing = outgoing
        self.text = text
        self.composerBackground = composerBackground
    }

    // Convenience default initializer uses platform-safe defaults
    public init() {
        self.background = ChatTheme.defaultBackground
        self.incoming = Color.gray.opacity(0.2)
        self.outgoing = Color.accentColor.opacity(0.2)
        self.text = .primary
        self.composerBackground = ChatTheme.defaultComposerBackground
    }
}

private extension ChatTheme {
    static var defaultBackground: Color {
        #if os(iOS)
        return Color(UIColor.systemBackground)
        #elseif os(macOS)
        return Color(NSColor.windowBackgroundColor)
        #else
        return Color.white
        #endif
    }
    static var defaultComposerBackground: Color {
        #if os(iOS)
        return Color(UIColor.secondarySystemBackground)
        #elseif os(macOS)
        return Color(NSColor.controlBackgroundColor)
        #else
        return Color.gray.opacity(0.12)
        #endif
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
