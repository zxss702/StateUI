// swift-tools-version:6.4
import PackageDescription

// The Android Views host: Swift in the application's process, reading the
// typed patch and calling the views through JNI. A sibling package, as the
// AppKit host is, so the one dynamic SwiftOmniUI runtime is linked into the
// application rather than copied into a second library in the same process.
// It builds for Android alone: .scripts/Android/build-swift.sh names the Swift
// SDK and the triple.
let package = Package(
    name: "SwiftOmniUIAndroid",
    products: [
        .library(name: "SwiftOmniUIAndroid", type: .dynamic, targets: ["SwiftOmniUIAndroid"]),
    ],
    dependencies: [
        .package(name: "SwiftOmniUICore", path: "../SwiftOmniUI/Sources"),
        .package(name: "SwiftOmniUIHost", path: "../SwiftOmniUI.Host"),
    ],
    targets: [
        // The NDK's C surface: JNI, the main thread's looper, the display's
        // frames, the log.
        .target(
            name: "CSwiftOmniUIAndroid",
            path: "Sources/CSwiftOmniUIAndroid",
            linkerSettings: [.linkedLibrary("android"), .linkedLibrary("log")]
        ),
        .target(
            name: "SwiftOmniUIAndroid",
            dependencies: ["CSwiftOmniUIAndroid", .product(name: "SwiftOmniUI", package: "SwiftOmniUICore"),
                .product(name: "SwiftOmniUIHost", package: "SwiftOmniUIHost")],
            path: "Sources/SwiftOmniUIAndroid",
            swiftSettings: [.enableUpcomingFeature("NonisolatedNonsendingByDefault")]
        ),
    ]
)
