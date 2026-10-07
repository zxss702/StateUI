// swift-tools-version:6.4
import PackageDescription

// A separate package is deliberate, as AppKit's is: a sibling host package makes SwiftPM link the one dynamic
// SwiftOmniUI runtime into the application instead of copying SwiftOmniUI's object files into a second library.
let package = Package(
    name: "SwiftOmniUIUIKit",
    platforms: [.iOS(.v26)],
    products: [
        .library(name: "SwiftOmniUIUIKit", type: .dynamic, targets: ["SwiftOmniUIUIKit"]),
    ],
    dependencies: [
        .package(name: "SwiftOmniUICore", path: "../SwiftOmniUI/Sources"),
        .package(name: "SwiftOmniUIHost", path: "../SwiftOmniUI.Host"),
    ],
    targets: [
        .target(
            name: "SwiftOmniUIUIKit",
            dependencies: [.product(name: "SwiftOmniUI", package: "SwiftOmniUICore"),
                .product(name: "SwiftOmniUIHost", package: "SwiftOmniUIHost")],
            path: "Sources",
            swiftSettings: [.enableUpcomingFeature("NonisolatedNonsendingByDefault")],
            linkerSettings: [.linkedFramework("UIKit")]
        ),
    ]
)
