# swiftuiChat – Multiplatform Clean Architecture Chat App

This workspace includes a production-grade, modular chat architecture for iOS, iPadOS, macOS, and watchOS.

Highlights:
- Clean Architecture with separate Domain, Presentation, UI, and Data (Firebase) layers
- Swift Package modules for easy integration into other apps
- Test-driven (XCTest) with in-memory repository for fast unit tests
- Swift Concurrency (async/await, AsyncSequence) driven APIs
- Highly customizable UI with themes and styling hooks
- GitHub Actions CI for build and test

## Modules

- ChatCore (Swift Package)
  - ChatDomain: Entities, repository protocols, use cases
  - ChatPresentation: View models, DI container
  - ChatUI: SwiftUI views, themes, simple chat screen
  - ChatTestUtils: Test data builders and mocks
  - ChatData: Data layer (DataSource protocols, repository impl, in‑memory and SwiftData data sources)
- ChatFirebase (Swift Package)
  - ChatDataFirebase: Firestore-based repository for iOS and macOS

watchOS note: Firebase Firestore is not supported on watchOS. The watch app can use the ChatCore layers and either:
- rely on an in-memory/local repository, or
- communicate with the iOS app via WatchConnectivity where iOS performs Firebase operations.

## Run locally (no Firebase required)
The app uses an in-memory chat repository by default so you can build and run immediately after adding the ChatCore package to the Xcode project.

### Add local package to Xcode
- File > Add Packages… > Add Local > select `swiftuiChat/Packages/ChatCore`.
- Add `ChatDomain`, `ChatPresentation`, `ChatUI`, and `ChatData` to the `swiftuiChat` app target.

### Use SwiftData (optional)
- Requires iOS 17+/macOS 14+.
- Enable SwiftData data source: set `CHAT_SWIFTDATA=1`.
- Choose store type:
  - In-memory (ephemeral): set `CHAT_SWIFTDATA_INMEMORY=1`
  - On-disk (persistent, default when not set): omit the flag
- Example (CLI):
  - `CHAT_SWIFTDATA=1 CHAT_SWIFTDATA_INMEMORY=1 xcodebuild -project swiftuiChat.xcodeproj -scheme swiftuiChat build`
  - `CHAT_SWIFTDATA=1 xcodebuild -project swiftuiChat.xcodeproj -scheme swiftuiChat build`

### SwiftData persistence & migration
- SwiftData uses the default app container when on-disk. No extra setup needed.
- Lightweight schema changes (adding optional properties) are supported by SwiftData.
- For breaking schema changes, bump models and plan a data reset or migration strategy.

### Use the reusable Chat UI
Replace `ContentView` with the code in the “Integration snippet” below.

## Integrate Firebase (iOS/macOS)
1. Add your `GoogleService-Info.plist` to the iOS and macOS app targets in Xcode.
2. Add the local package `swiftuiChat/Packages/ChatFirebase`.
3. Replace the in-memory repository with `FirestoreChatRepository` from ChatDataFirebase.
4. Call `FirebaseApp.configure()` in your App entry on iOS/macOS.

## CI
GitHub Actions workflow runs `swift test` on the packages. See `.github/workflows/ci.yml`.

## Customize UI
Use `ChatTheme` in ChatUI to tailor colors, shapes, and spacing.

## Integration snippet
```swift
import SwiftUI
import ChatDomain
import ChatPresentation
import ChatUI
import ChatData

struct ContentView: View {
    @StateObject private var vm: ChatViewModel

    init() {
        let repo = ChatRepositoryImpl(dataSource: InMemoryChatDataSource())
        let container = ChatContainer(repo: repo)
        let currentUser = ChatUser(id: "me", displayName: "Me")
        // Create a chat synchronously for demo purposes
        // In a real app, handle this via async flow
        var chatId = "demo"
        Task { @MainActor in
            if let chat = try? await container.createChat(members: [currentUser]) {
                chatId = chat.id
            }
        }
        _vm = StateObject(wrappedValue: ChatViewModel(
            chatId: chatId,
            currentUser: currentUser,
            observeMessages: container.observeMessages,
            sendMessage: container.sendMessage
        ))
    }

    var body: some View {
        ChatView(viewModel: vm, currentUserId: "me")
    }
}
```

## License
This template is intended for portfolio and production use. Validate dependencies and policies for your organization.
