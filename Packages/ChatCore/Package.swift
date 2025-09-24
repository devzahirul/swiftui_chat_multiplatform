// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ChatCore",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v16),
        .macOS(.v13),
        .watchOS(.v9)
    ],
    products: [
        .library(name: "ChatDomain", targets: ["ChatDomain"]),
        .library(name: "ChatPresentation", targets: ["ChatPresentation"]),
        .library(name: "ChatUI", targets: ["ChatUI"]),
        .library(name: "ChatTestUtils", targets: ["ChatTestUtils"]),
        .library(name: "ChatData", targets: ["ChatData"]), // Data layer (in-memory data source + repo impl)
        // Auth (Sign in with Apple) — single product exposing all layers
        .library(name: "LoginWithApple", targets: ["LoginWithApple"]) 
    ],
    dependencies: [],
    targets: [
        .target(name: "ChatDomain", dependencies: []),
        .target(name: "ChatPresentation", dependencies: [
            "ChatDomain"
        ]),
        .target(name: "ChatUI", dependencies: ["ChatDomain", "ChatPresentation"]),
        .target(name: "ChatTestUtils", dependencies: ["ChatDomain"], path: "Sources/ChatTestUtils"),
        .target(name: "ChatData", dependencies: ["ChatDomain"], path: "Sources/ChatData"),
        // Login/Auth targets
        .target(name: "LoginDomain", dependencies: ["ChatDomain"], path: "Sources/LoginWithApple/LoginDomain"),
        .target(name: "LoginData", dependencies: ["LoginDomain"], path: "Sources/LoginWithApple/LoginData"),
        .target(name: "LoginPresentation", dependencies: ["LoginDomain"], path: "Sources/LoginWithApple/LoginPresentation"),
        .target(name: "LoginUI", dependencies: ["LoginPresentation", "ChatDomain"], path: "Sources/LoginWithApple/LoginUI"),
        // Umbrella target that re-exports the login modules
        .target(name: "LoginWithApple", dependencies: ["LoginDomain", "LoginData", "LoginPresentation", "LoginUI"], path: "Sources/LoginWithApple"),
        .testTarget(name: "ChatDomainTests", dependencies: ["ChatDomain", "ChatTestUtils", "ChatData"]),
        .testTarget(name: "ChatPresentationTests", dependencies: ["ChatPresentation", "ChatTestUtils", "ChatData"])    ]
)
