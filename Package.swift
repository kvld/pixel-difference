// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "PixelDifference",
    products: [
        .library(
            name: "PixelDifference",
            targets: ["PixelDifference"]
        ),
    ],
    targets: [
        .target(
            name: "PixelDifference",
            path: "Sources/"
        ),
        .testTarget(
            name: "PixelDifferenceTests",
            dependencies: ["PixelDifference"],
            path: "Tests/",
            resources: [.copy("Resources")]
        )
    ]
)
