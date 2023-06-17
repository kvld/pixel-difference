// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SwiftPixelmatch",
    platforms: [.iOS(.v13), .macOS(.v10_15)],
    products: [
        .library(
            name: "SwiftPixelmatch",
            targets: ["SwiftPixelmatch"]
        ),
    ],
    targets: [
        .target(
            name: "SwiftPixelmatch",
            path: "Sources/"
        ),
        .testTarget(
            name: "SwiftPixelmatchTests",
            dependencies: ["SwiftPixelmatch"],
            path: "Tests/",
            resources: [.copy("Resources")]
        )
    ]
)
