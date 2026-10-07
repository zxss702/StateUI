// swift-tools-version:6.4
import PackageDescription

// The web view's GTK backend: WebKitGTK 6.0's web view, realized through the
// GTK host's registration of an application's own controls. A package of its
// own because WebKitGTK is a library the platform does not ship with GTK: an
// application showing a web view on GTK depends on it from its GTK head and
// calls SwiftOmniUIWebViewGTK.register() before it runs; nothing else links WebKit.
// The GTK host's tests register it and run the web view's family through it.

// NonisolatedNonsendingByDefault, as every SwiftOmniUI package; see ../../../Package.swift.
let settings: [SwiftSetting] = [.enableUpcomingFeature("NonisolatedNonsendingByDefault"), .define("GTK")]

let package = Package(
    name: "SwiftOmniUIWebViewGTK",
    products: [
        // Dynamic, as the GTK host is: a head links it once beside the host.
        .library(name: "SwiftOmniUIWebViewGTK", type: .dynamic, targets: ["SwiftOmniUIWebViewGTK"]),
    ],
    dependencies: [
        .package(name: "SwiftOmniUIRoot", path: "../../.."),
        .package(name: "SwiftOmniUIHost", path: "../../SwiftOmniUI.Host"),
        .package(name: "SwiftOmniUIGTK", path: "../../SwiftOmniUI.GTK"),
    ],
    targets: [
        // WebKitGTK 6.0's calls, declared by themselves; pkg-config links the engine.
        .systemLibrary(name: "CWebKitGTK", path: "Sources/CWebKitGTK", pkgConfig: "webkitgtk-6.0"),
        .target(
            name: "SwiftOmniUIWebViewGTK",
            dependencies: [
                "CWebKitGTK",
                .product(name: "SwiftOmniUIHost", package: "SwiftOmniUIHost"),
                .product(name: "SwiftOmniUIGTK", package: "SwiftOmniUIGTK"),
                .product(name: "SwiftOmniUI", package: "SwiftOmniUIRoot"),
            ],
            path: "Sources/SwiftOmniUIWebViewGTK", swiftSettings: settings),
    ]
)
