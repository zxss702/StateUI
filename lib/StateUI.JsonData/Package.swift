// swift-tools-version:6.4
import PackageDescription

// The JsonData model layer's bridge: `@Query`, `.modelContainer` and
// `\.modelContext` as StateUI's environment and differ can carry them. A
// sibling package rather than part of the core, which holds no Foundation and
// no dependencies - the core publishes alone; an application using JsonData
// links this beside it.
let package = Package(
    name: "StateUIJsonData",
    platforms: [
        .iOS(.v26),
        .macCatalyst(.v26),
        .macOS(.v15),
    ],
    products: [
        .library(name: "StateUIJsonData", type: .dynamic, targets: ["StateUIJsonData"]),
    ],
    dependencies: [
        .package(name: "StateUIRoot", path: "../.."),
        // The checkout a machine holds: Packges/JsonData beside Packges/StateUI
        // locally, zxs20/JsonData beside zxs20/StateUI on Windows.
        .package(url: "https://github.com/zxss702/JsonData.git", branch: "main"),
    ],
    targets: [
        .target(
            name: "StateUIJsonData",
            dependencies: [
                .product(name: "StateUI", package: "StateUIRoot"),
                // Dynamic beside the bridge's own dynamic product, so one
                // model layer is shared by every library that names it.
                .product(name: "JsonDataDynamic", package: "JsonData"),
            ],
            path: "Sources",
            swiftSettings: [.enableUpcomingFeature("NonisolatedNonsendingByDefault")]
        ),
        .testTarget(
            name: "StateUIJsonDataTests",
            dependencies: ["StateUIJsonData"],
            path: "Tests",
            swiftSettings: [.enableUpcomingFeature("NonisolatedNonsendingByDefault")]
        ),
    ]
)
