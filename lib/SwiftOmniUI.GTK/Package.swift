// swift-tools-version:6.4
import PackageDescription

// The GTK 4 host: Swift in the application's process, reading the typed patch
// and calling GTK 4 and libadwaita through their C API - no relay beneath it.
// A sibling package, as the AppKit, Android Views and WinUI hosts are, so the
// one dynamic SwiftOmniUI runtime is linked into the application rather than
// copied into a second library in the same process. It builds on Linux, where
// pkg-config finds libadwaita and the GTK it needs.
let package = Package(
    name: "SwiftOmniUIGTK",
    products: [
        .library(name: "SwiftOmniUIGTK", type: .dynamic, targets: ["SwiftOmniUIGTK"]),
    ],
    dependencies: [
        .package(name: "SwiftOmniUIRoot", path: "../.."),
        .package(name: "SwiftOmniUIHost", path: "../SwiftOmniUI.Host"),
        .package(name: "SwiftOmniUIConformance", path: "../SwiftOmniUI.Conformance"),
        .package(name: "SwiftOmniUIWebViewGTK", path: "../Backends/WebView.GTK"),
    ],
    targets: [
        // GTK's and libadwaita's headers and libraries, and nothing else.
        .systemLibrary(name: "CSwiftOmniUIGTK", path: "Sources/CSwiftOmniUIGTK", pkgConfig: "libadwaita-1"),
        .target(
            name: "SwiftOmniUIGTK",
            dependencies: ["CSwiftOmniUIGTK", .product(name: "SwiftOmniUI", package: "SwiftOmniUIRoot"),
                .product(name: "SwiftOmniUIHost", package: "SwiftOmniUIHost")],
            path: "Sources/SwiftOmniUIGTK",
            resources: [.copy("Resources/Icons")],
            swiftSettings: [.enableUpcomingFeature("NonisolatedNonsendingByDefault")]
        ),
        .testTarget(
            name: "SwiftOmniUIGTKTests",
            dependencies: [
                "SwiftOmniUIGTK", "CSwiftOmniUIGTK", .product(name: "SwiftOmniUI", package: "SwiftOmniUIRoot"),
                .product(name: "SwiftOmniUIHost", package: "SwiftOmniUIHost"),
                .product(name: "SwiftOmniUIConformance", package: "SwiftOmniUIConformance"),
                .product(name: "SwiftOmniUIWebViewGTK", package: "SwiftOmniUIWebViewGTK"),
            ],
            path: "Tests",
            exclude: ["Resources"],
            swiftSettings: [.enableUpcomingFeature("NonisolatedNonsendingByDefault")]
        ),
    ]
)
