// swift-tools-version:6.4
import PackageDescription

// A separate package is deliberate. Keeping AppKit as a sibling host package
// makes SwiftPM link the one dynamic SwiftOmniUI runtime into the executable instead
// of copying SwiftOmniUI's object files into a second library in the same process.
let package = Package(
    name: "SwiftOmniUIAppKit",
    platforms: [.macOS(.v15)],
    products: [
        .library(name: "SwiftOmniUIAppKit", type: .dynamic, targets: ["SwiftOmniUIAppKit"]),
    ],
    dependencies: [
        .package(name: "SwiftOmniUICore", path: "../SwiftOmniUI/Sources"),
        .package(name: "SwiftOmniUIHost", path: "../SwiftOmniUI.Host"),
        .package(name: "SwiftOmniUIConformance", path: "../SwiftOmniUI.Conformance"),
    ],
    targets: [
        .target(
            name: "SwiftOmniUIAppKit",
            dependencies: [.product(name: "SwiftOmniUI", package: "SwiftOmniUICore"),
                .product(name: "SwiftOmniUIHost", package: "SwiftOmniUIHost")],
            path: "Sources",
            swiftSettings: [.enableUpcomingFeature("NonisolatedNonsendingByDefault")],
            linkerSettings: [.linkedFramework("AppKit")]
        ),
        .testTarget(
            name: "SwiftOmniUIAppKitTests",
            dependencies: [
                "SwiftOmniUIAppKit",
                .product(name: "SwiftOmniUI", package: "SwiftOmniUICore"),
                .product(name: "SwiftOmniUIHost", package: "SwiftOmniUIHost"),
                .product(name: "SwiftOmniUIConformance", package: "SwiftOmniUIConformance"),
            ],
            path: "Tests",
            exclude: ["Resources"],
            swiftSettings: [.enableUpcomingFeature("NonisolatedNonsendingByDefault")],
            linkerSettings: [.linkedFramework("AppKit")]
        ),
    ]
)
