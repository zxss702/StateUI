// swift-tools-version:6.4
import PackageDescription

// The web view's WinUI backend: WinUI's WebView2, made by this package's
// C++/WinRT relay and realized through the WinUI host's registration of an
// application's own controls. A package of its own because WebView2 needs a
// runtime the platform does not ship with WinUI: an application showing a web
// view on WinUI depends on it from its WinUI head and calls
// SwiftOmniUIWebViewWinUI.register() before it runs. The relay includes the
// projection the WinUI host generated.
let settings: [SwiftSetting] = [.enableUpcomingFeature("NonisolatedNonsendingByDefault"), .define("WINUI")]

let package = Package(
    name: "SwiftOmniUIWebViewWinUI",
    products: [
        // Dynamic, as the WinUI host is: a head links it once beside the host.
        .library(name: "SwiftOmniUIWebViewWinUI", type: .dynamic, targets: ["SwiftOmniUIWebViewWinUI"]),
    ],
    dependencies: [
        .package(name: "SwiftOmniUIRoot", path: "../../.."),
        .package(name: "SwiftOmniUIHost", path: "../../SwiftOmniUI.Host"),
        .package(name: "SwiftOmniUIWinUI", path: "../../SwiftOmniUI.WinUI"),
    ],
    targets: [
        // WinUI's WebView2, C++/WinRT behind C functions.
        .target(
            name: "CWebViewWinUI",
            path: "Relay",
            cxxSettings: [.unsafeFlags(["-I", Context.packageDirectory + "/../../SwiftOmniUI.WinUI/.projection"])],
            linkerSettings: [.linkedLibrary("shcore"), .linkedLibrary("shlwapi")]
        ),
        .target(
            name: "SwiftOmniUIWebViewWinUI",
            dependencies: [
                "CWebViewWinUI",
                .product(name: "SwiftOmniUIHost", package: "SwiftOmniUIHost"),
                .product(name: "SwiftOmniUIWinUI", package: "SwiftOmniUIWinUI"),
                .product(name: "SwiftOmniUI", package: "SwiftOmniUIRoot"),
            ],
            path: "Sources/SwiftOmniUIWebViewWinUI", swiftSettings: settings),
    ],
    cxxLanguageStandard: .cxx20
)
