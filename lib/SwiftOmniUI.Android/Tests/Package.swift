// swift-tools-version:6.4
import PackageDescription

// The Android Views host's tests. A view exists only in an application's
// process, so the tests are a library the test APK loads, run on the UI thread
// by its instrumentation - Platforms/Android beside this file.
// .scripts/Android/test-android.sh builds, installs and runs them.
let package = Package(
    name: "SwiftOmniUIAndroidTests",
    products: [
        .library(name: "SwiftOmniUIAndroidTests", type: .dynamic, targets: ["SwiftOmniUIAndroidTests"]),
    ],
    dependencies: [
        .package(name: "SwiftOmniUICore", path: "../../SwiftOmniUI/Sources"),
        .package(name: "SwiftOmniUIAndroid", path: ".."),
        .package(name: "SwiftOmniUIHost", path: "../../SwiftOmniUI.Host"),
        .package(name: "SwiftOmniUIConformance", path: "../../SwiftOmniUI.Conformance"),
    ],
    targets: [
        .target(
            name: "SwiftOmniUIAndroidTests",
            dependencies: [
                .product(name: "SwiftOmniUI", package: "SwiftOmniUICore"),
                .product(name: "SwiftOmniUIAndroid", package: "SwiftOmniUIAndroid"),
                .product(name: "SwiftOmniUIHost", package: "SwiftOmniUIHost"),
                .product(name: "SwiftOmniUIConformance", package: "SwiftOmniUIConformance"),
            ],
            path: "Sources",
            swiftSettings: [.enableUpcomingFeature("NonisolatedNonsendingByDefault")]
        ),
    ]
)
