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
- Deep customization
  - ChatList slots: `headerContent`, `searchContent`, `emptyState`, `rowAccessory`
  - ChatView slots: `headerLeading`, `headerTrailing`, `messageAccessory`, `inputAccessory`
  - Message bubbles: `MessageBubbleStyle` protocol (default `MessengerBubbleStyle`)
  - Avatar/Input styles: `AvatarStyle`, `InputFieldStyle` (default Messenger styles)
  - Input field accessories: leading/trailing closures
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

## Slot & Style Examples

```swift
// 1) Custom header in the chat list
MessengerChatListView(
  viewModel: vm,
  currentUser: user,
  onChatSelected: { /* ... */ },
  onNewChatTapped: { /* ... */ },
  onHeaderAvatarTapped: { showProfile = true },
  headerContent: { CustomHeaderView(currentUser: user, onNewChatTapped: nil, onHeaderAvatarTapped: { showProfile = true }) },
  searchContent: { DefaultSearchBar() },
  emptyState: { DefaultEmptyState() },
  rowAccessory: { _ in DefaultRowAccessory() }
)

// 2) Per‑message accessory (e.g., typing / read receipts)
MessengerChatView(
  viewModel: chatVM,
  currentUserId: user.id,
  messageAccessory: { message, isOutgoing in
    if !isOutgoing && isTyping { TypingDotsView() } else { EmptyView() }
  },
  headerLeading: { EmptyView() },
  headerTrailing: { DefaultHeaderTrailing() },
  inputAccessory: { EmptyView() },
  onTyping: { isTyping in typingRepo.setTyping(chatId: chatId, userId: user.id, isTyping: isTyping) }
)

// 3) Swap bubble / avatar / input styles
struct BrandBubbleStyle: MessageBubbleStyle { /* ... */ }
AvatarView(style: MessengerAvatarStyle(), configuration: .init(initials: "A", size: 40, isOnline: true))
MessengerInputFieldStyle(leading: { AnyView(AttachButton()) }, trailing: { AnyView(SendButton()) })
```

## Resolver & Plugin Registry (No DI Framework)

```swift
// Plain resolver
let repo = ChatRepositoryImpl(dataSource: InMemoryChatDataSource())
let presence = InMemoryPresenceRepository()
let typing = InMemoryTypingRepository()
let env = ChatResolver.makeEnvironment(repo: repo, presenceRepo: presence, typingRepo: typing)

// Or use registry factories (e.g., in App startup)
ChatCoreRegistry.makeRepository = { ChatRepositoryImpl(dataSource: InMemoryChatDataSource()) }
ChatCoreRegistry.makePresenceRepository = { InMemoryPresenceRepository() }
ChatCoreRegistry.makeTypingRepository = { InMemoryTypingRepository() }
let env2 = ChatResolver.makeEnvironmentFromRegistry()
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

Contract tests (for data providers):
- Chat repository: `ChatRepositoryContractTests`
- Presence/typing: `PresenceTypingContractTests`

## Notes for macOS
- `LoginView` guards `AuthenticationServices` at compile time; Sign in with Apple requires iCloud session.
- Some iOS navigation modifiers are conditionally compiled and omitted on macOS.

## Presence & Typing (preview)
- Domain: `Presence`, `TypingIndicator`, `ChatEvent`.
- Protocols: `PresenceRepository`, `TypingRepository` with observe/update methods.
- Use cases: `ObservePresenceUseCase`, `UpdatePresenceUseCase`, `ObserveTypingUseCase`, `SetTypingUseCase`.
- UI: Surface typing indicators via `messageAccessory` or the chat header.

## Flags and Data Sources
- In‑memory Chat repository (default)
- SwiftData (iOS 17+/macOS 14+): set `CHAT_SWIFTDATA=1`
  - In‑memory store: `CHAT_SWIFTDATA_INMEMORY=1`
  - On‑disk store: omit the flag
  

## Customize UI
- Use `ChatTheme` (ChatUI) to style colors, typography, spacing.
- Replace header actions by providing `onHeaderAvatarTapped` and your own sheet/content.
- Override high‑level UI via ViewBuilder slots and styles:
  - ChatList: provide custom header/search/empty/row accessory.
  - ChatView: provide custom header actions, per‑message accessory, and input accessory.
  - Message bubbles: implement `MessageBubbleStyle` if you need a different look.

## Recipes

1) Custom message bubble style

```swift
import ChatUI

struct BrandBubbleStyle: MessageBubbleStyle {
  func makeBody(_ c: MessageBubbleConfiguration) -> some View {
    Text(c.message.text ?? "")
      .font(.system(size: 16, weight: .medium))
      .foregroundColor(c.isOutgoing ? .white : .black)
      .padding(.horizontal, 14).padding(.vertical, 10)
      .background(
        RoundedRectangle(cornerRadius: 14, style: .continuous)
          .fill(c.isOutgoing ? Color.blue : Color(white: 0.92))
      )
  }
}

// Usage
MessengerMessageRow(
  message: message,
  isOutgoing: message.senderId == currentUser.id,
  isLastInGroup: isLast,
  showTimestamp: showTime,
  style: BrandBubbleStyle()
)
```

2) Custom input style (buttons on the left/right)

```swift
import ChatUI

struct AttachButton: View { var body: some View { Image(systemName: "paperclip").font(.title3) } }
struct SendButton: View { let onSend: () -> Void; var body: some View { Button(action: onSend) { Image(systemName: "arrow.up.circle.fill").font(.title) } } }

// Option A: Use the built-in style wrapper
let inputStyle = MessengerInputFieldStyle(
  leading: { AnyView(AttachButton()) },
  trailing: { AnyView(SendButton(onSend: onSend)) }
)
inputStyle.makeBody(.init(text: $text, onSend: onSend, onTyping: onTyping))

// Option B: Provide accessories directly to MessengerInputField
MessengerInputField(
  text: $text,
  onSend: onSend,
  onTyping: onTyping,
  leadingAccessory: { AnyView(AttachButton()) },
  trailingAccessory: { AnyView(SendButton(onSend: onSend)) }
)
```

3) Presence in chat list header using AvatarStyle

```swift
import ChatUI

struct StatusAvatarStyle: AvatarStyle {
  func makeBody(_ c: AvatarConfiguration) -> some View {
    ZStack {
      Circle().fill(LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))
      Text(c.initials.prefix(1).uppercased())
        .font(.system(size: c.size * 0.6, weight: .semibold))
        .foregroundColor(.white)
    }
    .frame(width: c.size, height: c.size)
    .overlay(alignment: .bottomTrailing) {
      if c.isOnline { Circle().fill(Color.green).frame(width: c.size * 0.28, height: c.size * 0.28).overlay(Circle().stroke(Color.white, lineWidth: 2)) }
    }
  }
}

struct Header: View {
  let currentUser: ChatUser
  @StateObject var presence = UserPresenceController() // streams isOnline
  var body: some View {
    HStack(spacing: 16) {
      AvatarView(style: StatusAvatarStyle(), configuration: .init(initials: String(currentUser.displayName.prefix(1)), size: 24, isOnline: presence.isOnline))
      Text("Chats").font(MessengerTheme.Typography.headerTitle)
      Spacer()
    }
    .onAppear { presence.start(userId: currentUser.id) }
  }
}

// Pass it via MessengerChatListView headerContent slot
MessengerChatListView(
  viewModel: vm,
  currentUser: user,
  onChatSelected: { /* ... */ },
  headerContent: { Header(currentUser: user) },
  searchContent: { DefaultSearchBar() },
  emptyState: { DefaultEmptyState() },
  rowAccessory: { _ in DefaultRowAccessory() }
)
```

4) Typing indicator via messageAccessory + onTyping

```swift
// Controller that streams peer typing and publishes our typing
final class TypingController: ObservableObject {
  @Published var peerIsTyping = false
  private let typingRepo = InMemoryTypingRepository() // or your own TypingRepository
  private var task: Task<Void, Never>?
  func start(chatId: String, currentUserId: String) {
    task?.cancel()
    task = Task { [weak self] in
      do {
        for try await t in typingRepo.typingStream(chatId: chatId) {
          guard t.userId != currentUserId else { continue }
          await MainActor.run { self?.peerIsTyping = t.isTyping }
        }
      } catch { }
    }
  }
  func setTyping(chatId: String, userId: String, isTyping: Bool) {
    Task { try? await typingRepo.setTyping(chatId: chatId, userId: userId, isTyping: isTyping) }
  }
  deinit { task?.cancel() }
}

// Use in MessengerChatView slots
@StateObject var typing = TypingController()
MessengerChatView(
  viewModel: chatVM,
  currentUserId: user.id,
  messageAccessory: { _, isOutgoing in
    if !isOutgoing && typing.peerIsTyping { TypingDotsView() } else { EmptyView() }
  },
  headerLeading: { EmptyView() },
  headerTrailing: { DefaultHeaderTrailing() },
  inputAccessory: { EmptyView() },
  onTyping: { isTyping in typing.setTyping(chatId: chatId, userId: user.id, isTyping: isTyping) }
)
.onAppear { typing.start(chatId: chatId, currentUserId: user.id) }
```

5) Registry bootstrap (no DI, single place to configure data)

```swift
// At app startup (e.g., in App.init)
ChatCoreRegistry.makeRepository = { ChatRepositoryImpl(dataSource: InMemoryChatDataSource()) }
ChatCoreRegistry.makePresenceRepository = { InMemoryPresenceRepository() }
ChatCoreRegistry.makeTypingRepository = { InMemoryTypingRepository() }

// Build environment anywhere you need it
if let env = ChatResolver.makeEnvironmentFromRegistry() {
  // Chat use cases
  let observe = env.chat.observeMessages
  let send = env.chat.sendMessage
  let create = env.chat.createChat

  // Presence/typing (optional)
  if let p = env.presence {
    let observePresence = p.observePresence
    let updatePresence = p.updatePresence
    let observeTyping = p.observeTyping
    let setTyping = p.setTyping
    // Wire these into your UI as needed
  }
}
```

## Firebase (optional)
1. Add `GoogleService-Info.plist` to iOS/macOS targets.
2. Add local package `Packages/ChatFirebase` and link `ChatDataFirebase`.
3. Configure Firebase in App entry and swap repository wiring.

## License
This template is intended for portfolio and production use. Validate dependencies and policies for your organization.
