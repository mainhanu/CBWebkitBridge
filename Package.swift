// swift-tools-version:5.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "CBWebkitBridge",
    products: [
        // Products define the executables and libraries produced by a package, and make them visible to other packages.
        .library(
            name: "CBWebkitBridge",
            targets: ["CBWebkitBridge"]),
    ],
    dependencies: [
        .package(url: "https://github.com/SwiftyJSON/SwiftyJSON.git", from: "5.0.0")
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "CBWebkitBridge",
            dependencies: ["SwiftyJSON"]),
        .testTarget(
            name: "CBWebkitBridgeTests",
            dependencies: ["CBWebkitBridge"]),
    ]
)
