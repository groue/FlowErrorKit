// swift-tools-version: 6.4
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
        .library(name: "FlowErrorKit", targets: ["FlowErrorKit"]),
    ],
    dependencies: [
        .package(url: "https://github.com/pointfreeco/xctest-dynamic-overlay", from: "1.4.2"),
    ],
    targets: [
        .target(
            name: "FlowErrorKit",
            dependencies: [
                .product(name: "XCTestDynamicOverlay", package: "xctest-dynamic-overlay"),
            ],
            resources: [
                .process("Resources")
            ],
        ),
        .testTarget(
            name: "FlowErrorKitTests",
            dependencies: ["FlowErrorKit"],
        ),
    ]
)

for target in package.targets {
    var settings = target.swiftSettings ?? []
    settings.append(contentsOf: [
        .enableUpcomingFeature("ApproachableConcurrency"),
        .enableUpcomingFeature("MemberImportVisibility"),
    ])
    target.swiftSettings = settings
}
