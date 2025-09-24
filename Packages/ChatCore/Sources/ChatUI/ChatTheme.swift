import SwiftUI
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

public struct MessengerTheme: Equatable {
    // Colors - exact Messenger palette
    public static let messengerBlue = Color(red: 0/255, green: 132/255, blue: 255/255)
    public static let messengerBlueDark = Color(red: 0/255, green: 120/255, blue: 235/255)
    public static let incomingBubbleGray = Color(red: 242/255, green: 242/255, blue: 247/255)
    public static let incomingBubbleDark = Color(red: 44/255, green: 44/255, blue: 46/255)
    public static let backgroundLight = Color(red: 255/255, green: 255/255, blue: 255/255)
    public static let backgroundDark = Color(red: 0/255, green: 0/255, blue: 0/255)
    public static let searchBackground = Color(red: 118/255, green: 118/255, blue: 128/255).opacity(0.12)
    public static let separatorColor = Color(red: 199/255, green: 199/255, blue: 204/255)
    public static let activeGreen = Color(red: 52/255, green: 199/255, blue: 89/255)

    // Typography
    public struct Typography {
        public static let chatTitle = Font.system(size: 17, weight: .semibold)
        public static let chatSubtitle = Font.system(size: 15, weight: .regular)
        public static let timestamp = Font.system(size: 13, weight: .regular)
        public static let messageText = Font.system(size: 16, weight: .regular)
        public static let headerTitle = Font.system(size: 34, weight: .bold)
        public static let unreadCount = Font.system(size: 12, weight: .semibold)
    }

    // Spacing
    public struct Spacing {
        public static let chatRowHeight: CGFloat = 72
        public static let avatarSize: CGFloat = 56
        public static let smallAvatarSize: CGFloat = 32
        public static let messageBubbleRadius: CGFloat = 18
        public static let inputFieldHeight: CGFloat = 36
        public static let defaultPadding: CGFloat = 16
        public static let smallPadding: CGFloat = 8
        public static let messagePadding: CGFloat = 12
    }

    // Shadows and Effects
    public struct Effects {
        public static let bubbleShadow = Color.black.opacity(0.1)
        public static let avatarBorder = Color.white
    }

    // Theme properties
    public var background: Color
    public var incoming: Color
    public var outgoing: Color
    public var text: Color
    public var composerBackground: Color
    public var searchBackground: Color
    public var separator: Color
    public var activeStatus: Color

    public init(background: Color = MessengerTheme.backgroundLight,
                incoming: Color = MessengerTheme.incomingBubbleGray,
                outgoing: Color = MessengerTheme.messengerBlue,
                text: Color = .primary,
                composerBackground: Color = MessengerTheme.backgroundLight,
                searchBackground: Color = MessengerTheme.searchBackground,
                separator: Color = MessengerTheme.separatorColor,
                activeStatus: Color = MessengerTheme.activeGreen) {
        self.background = background
        self.incoming = incoming
        self.outgoing = outgoing
        self.text = text
        self.composerBackground = composerBackground
        self.searchBackground = searchBackground
        self.separator = separator
        self.activeStatus = activeStatus
    }

    public static let light = MessengerTheme()

    public static let dark = MessengerTheme(
        background: MessengerTheme.backgroundDark,
        incoming: MessengerTheme.incomingBubbleDark,
        outgoing: MessengerTheme.messengerBlueDark,
        text: .white,
        composerBackground: MessengerTheme.backgroundDark,
        searchBackground: Color(red: 58/255, green: 58/255, blue: 60/255),
        separator: Color(red: 58/255, green: 58/255, blue: 60/255),
        activeStatus: MessengerTheme.activeGreen
    )
}

// Legacy ChatTheme for backward compatibility
public typealias ChatTheme = MessengerTheme

public struct MessengerThemeKey: EnvironmentKey {
    public static let defaultValue = MessengerTheme.light
}

public extension EnvironmentValues {
    var messengerTheme: MessengerTheme {
        get { self[MessengerThemeKey.self] }
        set { self[MessengerThemeKey.self] = newValue }
    }

    // Legacy support
    var chatTheme: MessengerTheme {
        get { self[MessengerThemeKey.self] }
        set { self[MessengerThemeKey.self] = newValue }
    }
}
