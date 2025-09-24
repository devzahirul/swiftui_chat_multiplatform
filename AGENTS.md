# Repository Guidelines

## Project Structure & Modules
- `swiftuiChat/` — App entry (`swiftuiChatApp.swift`), DI setup (`DI.swift`), assets.
- `swiftuiChat.xcodeproj/` — Xcode project and schemes.
- `Packages/ChatCore/` — Clean Architecture layers:
  - `ChatDomain`, `ChatPresentation`, `ChatUI`, `ChatTestUtils`, `ChatData`.
- `Packages/ChatFirebase/` — `ChatDataFirebase` (Firestore repository).
- Tests live in `Packages/*/Tests/...` (XCTest).

## Build, Test, and Development
- Open in Xcode: `open swiftuiChat.xcodeproj`
- Build app (CLI, example simulator):
  `xcodebuild -project swiftuiChat.xcodeproj -scheme swiftuiChat -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 15' build`
- Build/test core package:
  - `swift build --package-path Packages/ChatCore`
  - `swift test --package-path Packages/ChatCore`
- Force in‑memory repo (useful for UI/dev): prefix commands with `CHAT_INMEMORY=1` and ensure the app target links `ChatData`.
- Use SwiftData data source (iOS 17+/macOS 14+): prefix with `CHAT_SWIFTDATA=1`.
  - In-memory SwiftData store: add `CHAT_SWIFTDATA_INMEMORY=1`
  - On-disk SwiftData store: omit `CHAT_SWIFTDATA_INMEMORY`

## Coding Style & Naming
- Swift 5; 4‑space indent; braces on same line; trailing commas allowed.
- Types `PascalCase`; methods/properties `camelCase`; protocols do not use “Protocol” suffix (e.g., `ChatRepository`).
- One primary type per file; names like `FeatureView.swift`, `FeatureViewModel.swift`.
- Keep APIs internal by default; prefer `struct` and `final class`.
- Wire dependencies via `swiftuiChat/DI.swift` (and package DI where applicable); avoid singletons outside DI.

## Testing Guidelines
- Framework: XCTest.
- File naming: `...Tests.swift`; test methods start with `test`.
- Fast unit tests: construct `ChatRepositoryImpl(dataSource: InMemoryChatDataSource())` from `ChatData`.
- Run: `swift test --package-path Packages/ChatCore` (and for Firebase if added).
- Aim to cover new or changed logic; keep CI green.

## Commit & Pull Requests
- Commit style: imperative subject with scope, e.g., `Core: add in‑memory repo`, `DI: register use cases`, `UI: polish chat row`.
- PRs must include: clear summary, linked issues (`Closes #123`), screenshots for UI changes, notes on DI/architecture impact, and passing tests.

## Security & Configuration
- Do not commit secrets (e.g., `GoogleService-Info.plist`). Add via Xcode targets locally.
- Firestore supported on iOS/macOS; use in‑memory or bridging for watchOS.
