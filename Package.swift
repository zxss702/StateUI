// swift-tools-version:6.4
import PackageDescription

// SwiftOmniUI through the package's URL.
//
// AT THE REPOSITORY ROOT, which is not a matter of taste: SwiftPM reads a
// package's manifest from the root of the checkout and nowhere else, so this is
// the one place it can sit if anybody is to write
//
//     .package(url: "https://github.com/zxss702/SwiftOmniUI.git", branch: "main")
//
// and reach every product the family publishes.
//
// The manifest holds no code of its own. Every product is an umbrella target -
// one source file - that depends on the product a sibling package under lib/
// already vends. That shape is what keeps one dynamic runtime in a process:
// target dependencies inside a package link statically, so declaring the host
// targets here would embed the core a second time wherever a consumer also
// links it; a product boundary is what makes SwiftPM link the dynamic library.
// The lib/ manifests remain the packages' own word: each builds and tests
// itself as before, and this root speaks only for what a checkout's URL sells.
//
// Hosts are declared for the machine the manifest runs on: a consumer
// resolving on Linux finds the GTK products, on Windows the WinUI ones, on
// macOS the AppKit one. UIKit, Android and Web are not yet declared - their
// builds are driven by scripts rather than a plain checkout.

let settings: [SwiftSetting] = [.enableUpcomingFeature("NonisolatedNonsendingByDefault")]

// A product the checkout sells and the sibling that builds it: the umbrella
// target of the same name stands between them, so a consumer names the product
// and the library comes through the sibling's own manifest.
func umbrella(_ product: String, _ package: String) -> Target {
    .target(
        name: "\(product)ThroughTheRoot",
        dependencies: [.product(name: product, package: package)],
        path: "Sources/ThroughTheRoot",
        sources: ["\(product).swift"],
        swiftSettings: settings
    )
}

var products: [Product] = [
    .library(name: "SwiftOmniUI", targets: ["SwiftOmniUIThroughTheRoot"]),
    .library(name: "SwiftOmniUIHost", targets: ["SwiftOmniUIHostThroughTheRoot"]),
    .library(name: "SwiftOmniUIFoundation", targets: ["SwiftOmniUIFoundationThroughTheRoot"]),
    .library(name: "SwiftOmniUIJsonData", targets: ["SwiftOmniUIJsonDataThroughTheRoot"]),
    .library(name: "SwiftOmniUIConformance", targets: ["SwiftOmniUIConformanceThroughTheRoot"]),
    .library(name: "SwiftOmniUIHead", targets: ["SwiftOmniUIHeadThroughTheRoot"]),
]

var dependencies: [Package.Dependency] = [
    .package(name: "SwiftOmniUICore", path: "lib/SwiftOmniUI/Sources"),
    .package(name: "SwiftOmniUIHost", path: "lib/SwiftOmniUI.Host"),
    .package(name: "SwiftOmniUIFoundation", path: "lib/SwiftOmniUI.Foundation"),
    .package(name: "SwiftOmniUIJsonData", path: "lib/SwiftOmniUI.JsonData"),
    .package(name: "SwiftOmniUIConformance", path: "lib/SwiftOmniUI.Conformance"),
    .package(name: "SwiftOmniUIHead", path: "lib/SwiftOmniUI.Head"),
]

var targets: [Target] = [
    // The core suite lives here: lib/SwiftOmniUI/Tests sits outside the
    // Sources/ package it covers, so the checkout root owns it.
    .testTarget(
        name: "SwiftOmniUITests",
        dependencies: [.product(name: "SwiftOmniUI", package: "SwiftOmniUICore")],
        path: "lib/SwiftOmniUI/Tests",
        swiftSettings: settings
    ),
    umbrella("SwiftOmniUI", "SwiftOmniUICore"),
    umbrella("SwiftOmniUIHost", "SwiftOmniUIHost"),
    umbrella("SwiftOmniUIFoundation", "SwiftOmniUIFoundation"),
    umbrella("SwiftOmniUIJsonData", "SwiftOmniUIJsonData"),
    umbrella("SwiftOmniUIConformance", "SwiftOmniUIConformance"),
    umbrella("SwiftOmniUIHead", "SwiftOmniUIHead"),
]

#if os(macOS)
products += [
    .library(name: "SwiftOmniUIAppKit", targets: ["SwiftOmniUIAppKitThroughTheRoot"]),
]
dependencies += [
    .package(name: "SwiftOmniUIAppKit", path: "lib/SwiftOmniUI.AppKit"),
]
targets += [
    umbrella("SwiftOmniUIAppKit", "SwiftOmniUIAppKit"),
]
#elseif os(Linux)
products += [
    .library(name: "SwiftOmniUIGTK", targets: ["SwiftOmniUIGTKThroughTheRoot"]),
    .library(name: "SwiftOmniUIWebViewGTK", targets: ["SwiftOmniUIWebViewGTKThroughTheRoot"]),
]
dependencies += [
    .package(name: "SwiftOmniUIGTK", path: "lib/SwiftOmniUI.GTK"),
    .package(name: "SwiftOmniUIWebViewGTK", path: "lib/Backends/WebView.GTK"),
]
targets += [
    umbrella("SwiftOmniUIGTK", "SwiftOmniUIGTK"),
    umbrella("SwiftOmniUIWebViewGTK", "SwiftOmniUIWebViewGTK"),
]
#elseif os(Windows)
products += [
    .library(name: "SwiftOmniUIWinUI", targets: ["SwiftOmniUIWinUIThroughTheRoot"]),
    .library(name: "SwiftOmniUIWebViewWinUI", targets: ["SwiftOmniUIWebViewWinUIThroughTheRoot"]),
]
dependencies += [
    .package(name: "SwiftOmniUIWinUI", path: "lib/SwiftOmniUI.WinUI"),
    .package(name: "SwiftOmniUIWebViewWinUI", path: "lib/Backends/WebView.WinUI"),
]
targets += [
    umbrella("SwiftOmniUIWinUI", "SwiftOmniUIWinUI"),
    umbrella("SwiftOmniUIWebViewWinUI", "SwiftOmniUIWebViewWinUI"),
]
#endif

let package = Package(
    name: "SwiftOmniUIRoot",
    // macOS 15 is the floor SCE (Logorythia) deploys to; iOS/Mac Catalyst stay
    // at 26, the releases upstream builds and tests against.
    platforms: [
        .iOS(.v26),
        .macCatalyst(.v26),
        .macOS(.v15),
    ],
    products: products,
    dependencies: dependencies,
    targets: targets
)
