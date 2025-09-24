import SwiftUI

public struct AvatarConfiguration {
    public let imageURL: String?
    public let initials: String
    public let size: CGFloat
    public let isOnline: Bool
    public init(imageURL: String? = nil, initials: String, size: CGFloat, isOnline: Bool) {
        self.imageURL = imageURL
        self.initials = initials
        self.size = size
        self.isOnline = isOnline
    }
}

public protocol AvatarStyle {
    associatedtype Body: View
    func makeBody(_ configuration: AvatarConfiguration) -> Body
}

public struct MessengerAvatarStyle: AvatarStyle {
    public init() {}
    public func makeBody(_ configuration: AvatarConfiguration) -> some View {
        MessengerAvatar(
            imageURL: configuration.imageURL,
            initials: configuration.initials,
            size: configuration.size,
            isOnline: configuration.isOnline,
            showStatusIndicator: configuration.isOnline
        )
    }
}

public struct AvatarView<Style: AvatarStyle>: View {
    let style: Style
    let configuration: AvatarConfiguration
    public init(style: Style, configuration: AvatarConfiguration) {
        self.style = style
        self.configuration = configuration
    }
    public var body: some View { style.makeBody(configuration) }
}

