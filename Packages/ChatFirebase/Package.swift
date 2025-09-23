// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ChatFirebase",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v16),
        .macOS(.v13)
    ],
    products: [
        .library(name: "ChatDataFirebase", targets: ["ChatDataFirebase"])  
    ],
    dependencies: [
        // Firebase via SPM — specify minimum versions as appropriate
        .package(url: "https://github.com/firebase/firebase-ios-sdk", from: "10.0.0"),
        .package(path: "../ChatCore")
    ],
    targets: [
        .target(
            name: "ChatDataFirebase",
            dependencies: [
                .product(name: "FirebaseFirestore", package: "firebase-ios-sdk"),
                .product(name: "FirebaseCore", package: "firebase-ios-sdk"),
                "ChatDomain"
            ]
        ),
        .testTarget(
            name: "ChatDataFirebaseTests",
            dependencies: ["ChatDataFirebase", "ChatTestUtils"]
        )
    ]
)
