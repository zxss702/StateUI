// swift-tools-version:6.4
import PackageDescription

// The UIKit host's tests. A view stands in a window scene only in an application's process, so the tests are an
// application of their own, run on the main thread once its first scene connects.
// .scripts/UIKit/test-uikit.sh builds, installs and runs it on a simulator.
let package = Package(
    name: "SwiftOmniUIUIKitTests",
    platforms: [.iOS(.v26)],
    products: [
        .executable(name: "SwiftOmniUIUIKitTests", targets: ["SwiftOmniUIUIKitTests"]),
    ],
    dependencies: [
        .package(name: "SwiftOmniUIRoot", path: "../../.."),
        .package(name: "SwiftOmniUIUIKit", path: ".."),
        .package(name: "SwiftOmniUIHost", path: "../../SwiftOmniUI.Host"),
        .package(name: "SwiftOmniUIConformance", path: "../../SwiftOmniUI.Conformance"),
    ],
    targets: [
        .executableTarget(
            name: "SwiftOmniUIUIKitTests",
            dependencies: [
                .product(name: "SwiftOmniUI", package: "SwiftOmniUIRoot"),
                .product(name: "SwiftOmniUIUIKit", package: "SwiftOmniUIUIKit"),
                .product(name: "SwiftOmniUIHost", package: "SwiftOmniUIHost"),
                .product(name: "SwiftOmniUIConformance", package: "SwiftOmniUIConformance"),
            ],
            path: "Sources",
            swiftSettings: [.enableUpcomingFeature("NonisolatedNonsendingByDefault")],
            linkerSettings: [.linkedFramework("XCTest"), .linkedFramework("UIKit")]
        ),
    ]
)
