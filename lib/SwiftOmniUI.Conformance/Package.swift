// swift-tools-version:6.4
import PackageDescription

// The conformance suite: what executing SwiftOmniUI's contract does, written once
// and run on every host against its real toolkit. Each host's test target
// links it and supplies a driver. A package of its own beside the core's tests,
// as the hosts are packages of their own, so the one dynamic SwiftOmniUI runtime is
// linked rather than copied.
let package = Package(
    name: "SwiftOmniUIConformance",
    platforms: [.iOS(.v26), .macOS(.v15)],
    products: [
        .library(name: "SwiftOmniUIConformance", targets: ["SwiftOmniUIConformance"]),
    ],
    dependencies: [
        .package(name: "SwiftOmniUIRoot", path: "../.."),
        .package(name: "SwiftOmniUIHost", path: "../SwiftOmniUI.Host"),
    ],
    targets: [
        .target(
            name: "SwiftOmniUIConformance",
            dependencies: [.product(name: "SwiftOmniUI", package: "SwiftOmniUIRoot"),
                .product(name: "SwiftOmniUIHost", package: "SwiftOmniUIHost")],
            path: "Sources",
            swiftSettings: [.enableUpcomingFeature("NonisolatedNonsendingByDefault")]
        ),
        .testTarget(
            name: "SwiftOmniUIConformanceTests",
            dependencies: ["SwiftOmniUIConformance", .product(name: "SwiftOmniUI", package: "SwiftOmniUIRoot"),
                .product(name: "SwiftOmniUIHost", package: "SwiftOmniUIHost")],
            path: "Tests",
            swiftSettings: [.enableUpcomingFeature("NonisolatedNonsendingByDefault")]
        ),
    ]
)
