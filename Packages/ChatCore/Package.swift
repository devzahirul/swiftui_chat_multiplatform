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
        .library(name: "ChatTestUtils", targets: ["ChatTestUtils"])
    ],
    dependencies: [],
    targets: [
        .target(name: "ChatDomain", dependencies: []),
        .target(name: "ChatPresentation", dependencies: [
            "ChatDomain"
        ]),
        .target(name: "ChatUI", dependencies: ["ChatDomain", "ChatPresentation"]),
        .target(name: "ChatTestUtils", dependencies: ["ChatDomain"], path: "Sources/ChatTestUtils"),
        .testTarget(name: "ChatDomainTests", dependencies: ["ChatDomain", "ChatTestUtils"]),
        .testTarget(name: "ChatPresentationTests", dependencies: ["ChatPresentation", "ChatTestUtils"])    ]
)
