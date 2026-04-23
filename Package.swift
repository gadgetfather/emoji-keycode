// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "EmojiKeycode",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "EmojiKeycode",
            path: "Sources/EmojiKeycode",
            resources: [.process("Resources")]
        ),
        .testTarget(
            name: "EmojiKeycodeTests",
            dependencies: ["EmojiKeycode"],
            path: "Tests/EmojiKeycodeTests"
        ),
    ]
)
