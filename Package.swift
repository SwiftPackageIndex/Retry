// swift-tools-version: 5.7

import PackageDescription

let package = Package(
    name: "Retry",
    products: [
        .library(name: "Retry", targets: ["Retry"]),
    ],
    targets: [
        .target(name: "Retry"),
        .testTarget(name: "RetryTests", dependencies: ["Retry"]),
    ]
)
