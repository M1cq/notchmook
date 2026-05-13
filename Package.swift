// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "NotchDesk",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "NotchDesk", targets: ["NotchDesk"])
    ],
    targets: [
        .executableTarget(
            name: "NotchDesk",
            path: "Sources/NotchDesk"
        )
    ]
)
