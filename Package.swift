// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ClaudeSwitch",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "ClaudeSwitch", targets: ["ClaudeSwitch"])
    ],
    targets: [
        .executableTarget(name: "ClaudeSwitch", path: "Sources/ClaudeSwitch")
    ]
)
