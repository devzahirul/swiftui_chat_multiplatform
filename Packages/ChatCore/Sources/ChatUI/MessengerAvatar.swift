import SwiftUI
import ChatDomain

public struct MessengerAvatar: View {
    let imageURL: String?
    let initials: String
    let size: CGFloat
    let isOnline: Bool
    let showStatusIndicator: Bool

    @Environment(\.messengerTheme) private var theme
    @State private var imageLoadFailed = false

    public init(
        imageURL: String? = nil,
        initials: String,
        size: CGFloat = MessengerTheme.Spacing.avatarSize,
        isOnline: Bool = false,
        showStatusIndicator: Bool = false
    ) {
        self.imageURL = imageURL
        self.initials = initials
        self.size = size
        self.isOnline = isOnline
        self.showStatusIndicator = showStatusIndicator
    }

    public var body: some View {
        ZStack {
            avatarContent
                .frame(width: size, height: size)
                .clipShape(Circle())
                .overlay {
                    Circle()
                        .stroke(MessengerTheme.Effects.avatarBorder, lineWidth: 1)
                }

            if showStatusIndicator {
                statusIndicator
            }
        }
    }

    @ViewBuilder
    private var avatarContent: some View {
        if let imageURL = imageURL, !imageLoadFailed {
            AsyncImage(url: URL(string: imageURL)) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                case .failure(_):
                    avatarPlaceholder
                        .onAppear {
                            imageLoadFailed = true
                        }
                case .empty:
                    avatarPlaceholder
                @unknown default:
                    avatarPlaceholder
                }
            }
        } else {
            avatarPlaceholder
        }
    }

    private var avatarPlaceholder: some View {
        ZStack {
            Circle()
                .fill(messengerGradient)

            Text(initials)
                .font(.system(size: size * 0.4, weight: .semibold))
                .foregroundColor(.white)
        }
    }

    private var messengerGradient: LinearGradient {
        LinearGradient(
            colors: [
                MessengerTheme.messengerBlue,
                Color(red: 110/255, green: 80/255, blue: 255/255)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var statusIndicator: some View {
        Circle()
            .fill(isOnline ? theme.activeStatus : Color.gray)
            .frame(width: size * 0.25, height: size * 0.25)
            .overlay {
                Circle()
                    .stroke(MessengerTheme.Effects.avatarBorder, lineWidth: 2)
            }
            .offset(x: size * 0.3, y: size * 0.3)
    }
}


// Messenger-style avatar variants
public extension MessengerAvatar {
    static func large(imageURL: String? = nil, initials: String, isOnline: Bool = false) -> MessengerAvatar {
        MessengerAvatar(
            imageURL: imageURL,
            initials: initials,
            size: MessengerTheme.Spacing.avatarSize,
            isOnline: isOnline,
            showStatusIndicator: true
        )
    }

    static func medium(imageURL: String? = nil, initials: String, isOnline: Bool = false) -> MessengerAvatar {
        MessengerAvatar(
            imageURL: imageURL,
            initials: initials,
            size: 40,
            isOnline: isOnline,
            showStatusIndicator: false
        )
    }

    static func small(imageURL: String? = nil, initials: String) -> MessengerAvatar {
        MessengerAvatar(
            imageURL: imageURL,
            initials: initials,
            size: MessengerTheme.Spacing.smallAvatarSize,
            isOnline: false,
            showStatusIndicator: false
        )
    }
}

// Chat user convenience initializers
public extension MessengerAvatar {
    init(user: ChatUser, size: CGFloat = MessengerTheme.Spacing.avatarSize, showStatusIndicator: Bool = false) {
        self.init(
            imageURL: nil, // user.profileImageURL when available
            initials: Self.initials(from: user.displayName),
            size: size,
            isOnline: false, // user.isOnline when available
            showStatusIndicator: showStatusIndicator
        )
    }

    private static func initials(from name: String) -> String {
        let parts = name.split(separator: " ")
        let first = parts.first?.first.map(String.init) ?? "?"
        let second = parts.dropFirst().first?.first.map(String.init) ?? ""
        return (first + second).uppercased()
    }
}