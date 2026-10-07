// swift-tools-version:6.4
import PackageDescription

// The Web host: Swift compiled to WebAssembly in the page, reading the typed patch and calling the DOM through the
// JavaScript relay in JavaScript/, whose functions CSwiftOmniUIWeb declares as the module's imports. A sibling package,
// as every host is. WebAssembly links no library dynamically: the application, SwiftOmniUI and this host are one
// module. It builds with the Swift SDK for WebAssembly, under SWIFTOMNIUI_HOST=web.
let package = Package(
    name: "SwiftOmniUIWeb",
    // The WebAssembly build reads no deployment target; this floors the macOS build so the core's macOS 15
    // floor is met there too.
    platforms: [.macOS(.v15)],
    products: [
        .library(name: "SwiftOmniUIWeb", targets: ["SwiftOmniUIWeb"]),
    ],
    dependencies: [
        .package(name: "SwiftOmniUICore", path: "../SwiftOmniUI/Sources"),
        .package(name: "SwiftOmniUIHost", path: "../SwiftOmniUI.Host"),
    ],
    targets: [
        // The relay's functions, and nothing else.
        .systemLibrary(name: "CSwiftOmniUIWeb", path: "Sources/CSwiftOmniUIWeb"),
        .target(
            name: "SwiftOmniUIWeb",
            dependencies: ["CSwiftOmniUIWeb", .product(name: "SwiftOmniUI", package: "SwiftOmniUICore"),
                .product(name: "SwiftOmniUIHost", package: "SwiftOmniUIHost")],
            path: "Sources/SwiftOmniUIWeb",
            swiftSettings: [.enableUpcomingFeature("NonisolatedNonsendingByDefault")]
        ),
    ]
)
