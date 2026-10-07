// swift-tools-version:6.4
import PackageDescription

// The host layer: the half of every SwiftOmniUI runtime no toolkit decides, which every host - AppKit, Android Views,
// WinUI, GTK - stands on. A dynamic library, as the core is, so a process holds one copy of its types.
let package = Package(
    name: "SwiftOmniUIHost",
    platforms: [
        .iOS(.v26),
        .macCatalyst(.v26),
        .macOS(.v15),
    ],
    products: [
        .library(name: "SwiftOmniUIHost", type: .dynamic, targets: ["SwiftOmniUIHost"]),
    ],
    dependencies: [
        .package(name: "SwiftOmniUIRoot", path: "../.."),
    ],
    targets: [
        .target(
            name: "SwiftOmniUIHost",
            dependencies: [.product(name: "SwiftOmniUI", package: "SwiftOmniUIRoot")],
            path: "Sources",
            swiftSettings: [.enableUpcomingFeature("NonisolatedNonsendingByDefault")]
        ),
        .testTarget(
            name: "SwiftOmniUIHostTests",
            dependencies: ["SwiftOmniUIHost", .product(name: "SwiftOmniUI", package: "SwiftOmniUIRoot")],
            path: "Tests",
            swiftSettings: [.enableUpcomingFeature("NonisolatedNonsendingByDefault")]
        ),
    ]
)
