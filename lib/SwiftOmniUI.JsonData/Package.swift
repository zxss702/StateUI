// swift-tools-version:6.4
import PackageDescription

// The JsonData model layer's bridge: `@Query`, `.modelContainer` and
// `\.modelContext` as SwiftOmniUI's environment and differ can carry them. A
// sibling package rather than part of the core, which holds no Foundation and
// no dependencies - the core publishes alone; an application using JsonData
// links this beside it.
let package = Package(
    name: "SwiftOmniUIJsonData",
    platforms: [
        .iOS(.v26),
        .macCatalyst(.v26),
        .macOS(.v15),
    ],
    products: [
        .library(name: "SwiftOmniUIJsonData", type: .dynamic, targets: ["SwiftOmniUIJsonData"]),
    ],
    dependencies: [
        .package(name: "SwiftOmniUICore", path: "../SwiftOmniUI/Sources"),
        // The checkout a machine holds: Packges/JsonData beside Packges/SwiftOmniUI
        // locally, zxs20/JsonData beside zxs20/SwiftOmniUI on Windows.
        .package(url: "https://github.com/zxss702/JsonData.git", branch: "main"),
    ],
    targets: [
        .target(
            name: "SwiftOmniUIJsonData",
            dependencies: [
                .product(name: "SwiftOmniUI", package: "SwiftOmniUICore"),
                // Dynamic beside the bridge's own dynamic product, so one
                // model layer is shared by every library that names it.
                .product(name: "JsonDataDynamic", package: "JsonData"),
            ],
            path: "Sources",
            swiftSettings: [.enableUpcomingFeature("NonisolatedNonsendingByDefault")]
        ),
        .testTarget(
            name: "SwiftOmniUIJsonDataTests",
            dependencies: ["SwiftOmniUIJsonData"],
            path: "Tests",
            swiftSettings: [.enableUpcomingFeature("NonisolatedNonsendingByDefault")]
        ),
    ]
)
