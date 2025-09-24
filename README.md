# swiftuiChat – Multiplatform Clean Architecture Chat App

This workspace contains a modular, production‑ready chat system for iOS, iPadOS, macOS, and watchOS.

- Clean Architecture: Domain, Data, Presentation, UI
- Swift Packages with composable features
- Swift Concurrency (async/await, AsyncSequence)
- XCTest coverage with fast in‑memory data source
- Highly customizable UI (themes, header actions)

## Packages and Modules

- ChatCore (Swift Package)
  - ChatDomain — Entities, repository protocols, use cases
  - ChatPresentation — View models, DI helpers (SwiftHilt)
  - ChatUI — SwiftUI components (Messenger‑style list, chat screen, theming)
  - ChatData — Data layer (in‑memory + SwiftData data sources, repository impl)
  - ChatTestUtils — Test builders/mocks
  - LoginWithApple (feature folder)
    - Product: `LoginWithApple` (single package product)
    - Targets included:
      - LoginDomain — `AuthRepository` abstraction
      - LoginData — `KeychainAuthRepository` (Keychain + UserDefaults)
      - LoginPresentation — `AuthStore` (observable auth state)
      - LoginUI — `LoginView` (Sign in with Apple), `ProfileView` (name/email), clipboard util
- ChatFirebase (Swift Package)
  - ChatDataFirebase — Firestore repository (iOS/macOS)

watchOS: Firestore is not supported. Use in‑memory or bridge via WatchConnectivity.

## Features

- Chat list, message view, input, avatars, themes (ChatUI)
- Sign in with Apple (LoginUI)
  - Keychain‑backed session, persisted display name + email
  - Packaged `LoginView` and `ProfileView`
  - Platform guards for macOS/watchOS
- Header customization
  - `MessengerChatListView` exposes `onHeaderAvatarTapped` so host apps decide what to show (Profile, Settings, etc.)

## Getting Started

1) Add local package(s) in Xcode
- File > Add Packages… > Add Local > select `swiftuiChat/Packages/ChatCore` (and `ChatFirebase` if needed).
- Link these products to your app target as needed:
  - Core chat: `ChatDomain`, `ChatPresentation`, `ChatUI`, `ChatData`
  - Login (Sign in with Apple): `LoginWithApple` (single product that includes domain, data, presentation, UI)

2) Enable Sign in with Apple
- App target > Signing & Capabilities > add “Sign in with Apple”.
- Ensure the entitlement `com.apple.developer.applesignin = Default` is present.

3) Choose a data source
- In‑memory repository (default): great for development/testing.
- SwiftData (iOS 17+/macOS 14+): set `CHAT_SWIFTDATA=1`.
  - In‑memory store: `CHAT_SWIFTDATA_INMEMORY=1`
  - On‑disk: omit the flag.

## Minimal Integration (Login + Chat)

```swift
import SwiftUI
import ChatDomain
import ChatPresentation
import ChatUI
import ChatData
import LoginWithApple

struct RootView: View {
    @StateObject private var auth = AuthStore(repo: KeychainAuthRepository())
    @State private var showProfile = false

    init() {
        // Optional: use provided DI wiring for ChatCore
        let c = Container(); useContainer(c); loadChatDependencies()
    }

    var body: some View {
        Group {
            if auth.currentUser != nil {
                // Example using header tap hook in MessengerChatListView
                ChatShell(onProfile: { showProfile = true })
                    .sheet(isPresented: $showProfile) {
                        ProfileView().environmentObject(auth)
                    }
            } else {
                LoginView().environmentObject(auth)
            }
        }
        .environmentObject(auth)
    }
}

// A thin wrapper you can customize; inside, use ChatUI.MessengerChatListView
struct ChatShell: View {
    var onProfile: () -> Void
    @StateObject private var listVM: ChatPresentation.ChatListViewModel
    private let currentUser = ChatUser(id: "me", displayName: "Me")

    init(onProfile: @escaping () -> Void) {
        self.onProfile = onProfile
        let getAll: GetAllChatsUseCase = resolve()
        let getLatest: GetLatestMessageUseCase = resolve()
        _listVM = StateObject(wrappedValue: ChatPresentation.ChatListViewModel(getAllChats: getAll, getLatestMessage: getLatest))
    }

    var body: some View {
        MessengerChatListView(
            viewModel: listVM,
            currentUser: currentUser,
            onChatSelected: { _ in },
            onNewChatTapped: {},
            onHeaderAvatarTapped: onProfile
        )
    }
}
```

To open Profile on header tap, pass a closure to `MessengerChatListView`:

```swift
MessengerChatListView(
  viewModel: vm,
  currentUser: user,
  onChatSelected: { /* ... */ },
  onNewChatTapped: { /* ... */ },
  onHeaderAvatarTapped: { showProfile = true }
)
.sheet(isPresented: $showProfile) {
  ProfileView().environmentObject(auth)
}
```

## Build & Test (CLI)
- Open in Xcode: `open swiftuiChat.xcodeproj`
- Build app: `xcodebuild -project swiftuiChat.xcodeproj -scheme swiftuiChat -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 15' build`
- Build core package: `swift build --package-path Packages/ChatCore`
- Test core package: `swift test --package-path Packages/ChatCore`

## Notes for macOS
- `LoginView` guards `AuthenticationServices` at compile time; Sign in with Apple requires iCloud session.
- Some iOS navigation modifiers are conditionally compiled and omitted on macOS.

## Flags and Data Sources
- In‑memory Chat repository (default)
- SwiftData (iOS 17+/macOS 14+): set `CHAT_SWIFTDATA=1`
  - In‑memory store: `CHAT_SWIFTDATA_INMEMORY=1`
  - On‑disk store: omit the flag
  

## Customize UI
- Use `ChatTheme` (ChatUI) to style colors, typography, spacing.
- Replace header actions by providing `onHeaderAvatarTapped` and your own sheet/content.

## Firebase (optional)
1. Add `GoogleService-Info.plist` to iOS/macOS targets.
2. Add local package `Packages/ChatFirebase` and link `ChatDataFirebase`.
3. Configure Firebase in App entry and swap repository wiring.

## License
This template is intended for portfolio and production use. Validate dependencies and policies for your organization.
