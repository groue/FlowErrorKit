// swift-tools-version: 6.4
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "FlowErrorKit",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v18),
        .macOS(.v15),
        .tvOS(.v18),
        .visionOS(.v2),
        .watchOS(.v11),
    ],
    products: [
        .library(name: "FlowErrorKit", targets: ["FlowErrorKit"]),
    ],
    dependencies: [
        .package(url: "https://github.com/pointfreeco/swift-issue-reporting", from: "2.1.0"),
    ],
    targets: [
        .target(
            name: "FlowErrorKit",
            dependencies: [
                .product(name: "IssueReporting", package: "swift-issue-reporting"),
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
