// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "FlowErrorKit",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v16),
        .macOS(.v14),
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "FlowErrorKit",
            targets: ["FlowErrorKit"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/pointfreeco/swift-issue-reporting", from: "1.8.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "FlowErrorKit",
            dependencies: [
                .product(name: "IssueReporting", package: "swift-issue-reporting"),
            ],
            resources: [
                .process("Resources")
            ]
        ),
        .testTarget(
            name: "FlowErrorKitTests",
            dependencies: ["FlowErrorKit"]
        ),
    ]
)

for target in package.targets {
    target.swiftSettings?.append(contentsOf: [
        .enableUpcomingFeature("InferIsolatedConformances"),
        .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
    ])
}
