// swift-tools-version: 6.2
import PackageDescription

// The core SwiftOmniUI library package. The manifest lives inside Sources/ so
// that a path dependency on it resolves under the "sources" package identity
// rather than colliding with the umbrella repository's own "swiftomniui"
// identity. The umbrella root re-exports this package's products.
let settings: [SwiftSetting] = [.enableUpcomingFeature("NonisolatedNonsendingByDefault")]
let package = Package(
    name: "SwiftOmniUICore",
    // macOS 15 is the floor SCE (Logorythia) deploys to; iOS/Mac Catalyst stay
    // at 26, the releases upstream builds and tests against.
    platforms: [
        .iOS(.v26),
        .macCatalyst(.v26),
        .macOS(.v15),
    ],
    products: [
        .library(name: "SwiftOmniUI", type: .dynamic, targets: ["SwiftOmniUI"]),
    ],
    targets: [
        .target(
            name: "SwiftOmniUI",
            path: ".",
            exclude: ["Package.swift"],
            swiftSettings: settings
        ),
    ]
)
