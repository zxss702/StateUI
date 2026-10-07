// swift-tools-version:6.4
import PackageDescription

// The SwiftOmniUI library and its host packages.
//
// A self-contained family of products: it knows nothing about any particular
// application, which is what allows it to be published and consumed on its own.
// An app provides its UI in a separate module that DEPENDS on these - see
// apps/Gallery/Sources/ in this repository for an example.
//
// AT THE REPOSITORY ROOT, which is not a matter of taste: SwiftPM reads a
// package's manifest from the root of the checkout and nowhere else, so this is
// the one place it can sit if anybody is to write
//
//     .package(url: "https://github.com/idexus/SwiftOmniUI.git", exact: "0.4.0")
//
// Everything a consumer can name is declared here - the core, the host layer
// and every host's product - each target's path pointing into lib/, where the
// code lives as sibling packages of its own. The per-package manifests under
// lib/ are unchanged: they are how each package's own suite builds and tests,
// while this manifest is what a URL dependency sees.
//
// Hosts are declared for the machine the manifest runs on: `#if os` gates keep
// `swift build` here building what this machine can, and a consumer resolving on
// Linux finds the GTK products, on Windows the WinUI ones, on macOS the AppKit
// one. UIKit, Android and Web are not yet declared - their builds are driven by
// scripts rather than a plain checkout.
//
// Sources are never listed: SwiftPM globs the target's path, and the build
// scripts glob the same tree. A new .swift file is picked up by both.

let settings: [SwiftSetting] = [.enableUpcomingFeature("NonisolatedNonsendingByDefault")]

// The host an application builds for: SWIFTOMNIUI_HOST - appkit, winui or gtk
// for the hosts declared here - read as the per-package manifests read it, so
// SwiftOmniUIHead re-exports the host the build names and marks its source.
let hosts: [String] = {
    #if os(macOS)
    ["AppKit"]
    #elseif os(Windows)
    ["WinUI"]
    #elseif os(Linux)
    ["GTK"]
    #else
    []
    #endif
}()
let host = hosts.first { $0.lowercased() == Context.environment["SWIFTOMNIUI_HOST"] }

var products: [Product] = [
    .library(name: "SwiftOmniUI", type: .dynamic, targets: ["SwiftOmniUI"]),
    .library(name: "SwiftOmniUIHost", type: .dynamic, targets: ["SwiftOmniUIHost"]),
    .library(name: "SwiftOmniUIFoundation", type: .dynamic, targets: ["SwiftOmniUIFoundation"]),
    .library(name: "SwiftOmniUIJsonData", type: .dynamic, targets: ["SwiftOmniUIJsonData"]),
    .library(name: "SwiftOmniUIConformance", targets: ["SwiftOmniUIConformance"]),
    .library(name: "SwiftOmniUIHead", targets: ["SwiftOmniUIHead"]),
]

var targets: [Target] = [
    .target(
        name: "SwiftOmniUI",
        path: "lib/SwiftOmniUI/Sources",
        swiftSettings: settings
    ),
    .target(
        name: "SwiftOmniUIHost",
        dependencies: ["SwiftOmniUI"],
        path: "lib/SwiftOmniUI.Host/Sources",
        swiftSettings: settings
    ),
    .target(
        name: "SwiftOmniUIFoundation",
        dependencies: ["SwiftOmniUI"],
        path: "lib/SwiftOmniUI.Foundation/Sources",
        swiftSettings: settings
    ),
    .target(
        name: "SwiftOmniUIJsonData",
        dependencies: [
            "SwiftOmniUI",
            // Dynamic beside the bridge's own dynamic product, so one model
            // layer is shared by every library that names it.
            .product(name: "JsonDataDynamic", package: "JsonData"),
        ],
        path: "lib/SwiftOmniUI.JsonData/Sources",
        swiftSettings: settings
    ),
    .target(
        name: "SwiftOmniUIConformance",
        dependencies: ["SwiftOmniUI", "SwiftOmniUIHost"],
        path: "lib/SwiftOmniUI.Conformance/Sources",
        swiftSettings: settings
    ),
    .target(
        name: "SwiftOmniUIHead",
        dependencies: host.map { [Target.Dependency.target(name: "SwiftOmniUI\($0)")] } ?? [],
        path: "lib/SwiftOmniUI.Head/Sources",
        swiftSettings: settings + (host.map { [.define($0.uppercased())] } ?? []),
        // A WinUI head is a windowed application: started by itself it opens no console, and started from one it
        // writes there.
        linkerSettings: host == "WinUI"
            ? [.unsafeFlags(["-Xlinker", "/SUBSYSTEM:WINDOWS", "-Xlinker", "/ENTRY:mainCRTStartup"])]
            : []
    ),
    .testTarget(
        name: "SwiftOmniUITests",
        dependencies: ["SwiftOmniUI"],
        path: "lib/SwiftOmniUI/Tests",
        swiftSettings: settings
    ),
]

#if os(macOS)
products += [
    .library(name: "SwiftOmniUIAppKit", type: .dynamic, targets: ["SwiftOmniUIAppKit"]),
]
targets += [
    .target(
        name: "SwiftOmniUIAppKit",
        dependencies: ["SwiftOmniUI", "SwiftOmniUIHost"],
        path: "lib/SwiftOmniUI.AppKit/Sources",
        swiftSettings: settings,
        linkerSettings: [.linkedFramework("AppKit")]
    ),
]
#elseif os(Linux)
products += [
    .library(name: "SwiftOmniUIGTK", type: .dynamic, targets: ["SwiftOmniUIGTK"]),
    .library(name: "SwiftOmniUIWebViewGTK", type: .dynamic, targets: ["SwiftOmniUIWebViewGTK"]),
]
targets += [
    // GTK's and libadwaita's headers and libraries, and nothing else.
    .systemLibrary(name: "CSwiftOmniUIGTK", path: "lib/SwiftOmniUI.GTK/Sources/CSwiftOmniUIGTK", pkgConfig: "libadwaita-1"),
    .target(
        name: "SwiftOmniUIGTK",
        dependencies: ["CSwiftOmniUIGTK", "SwiftOmniUI", "SwiftOmniUIHost"],
        path: "lib/SwiftOmniUI.GTK/Sources/SwiftOmniUIGTK",
        resources: [.copy("Resources/Icons")],
        swiftSettings: settings
    ),
    // WebKitGTK 6.0's calls, declared by themselves; pkg-config links the engine.
    .systemLibrary(name: "CWebKitGTK", path: "lib/Backends/WebView.GTK/Sources/CWebKitGTK", pkgConfig: "webkitgtk-6.0"),
    .target(
        name: "SwiftOmniUIWebViewGTK",
        dependencies: ["CWebKitGTK", "SwiftOmniUI", "SwiftOmniUIHost", "SwiftOmniUIGTK"],
        path: "lib/Backends/WebView.GTK/Sources/SwiftOmniUIWebViewGTK",
        swiftSettings: settings + [.define("GTK")]
    ),
]
#elseif os(Windows)
products += [
    .library(name: "SwiftOmniUIWinUI", type: .dynamic, targets: ["SwiftOmniUIWinUI"]),
    .library(name: "SwiftOmniUIWebViewWinUI", type: .dynamic, targets: ["SwiftOmniUIWebViewWinUI"]),
]
targets += [
    // The relay: WinUI's subclasses, its events, the doorbell's post and the frame clock, behind the C functions
    // its header declares. The headerSearchPath is the target's, so it lands on .projection as the WinUI
    // package's own manifest writes it.
    .target(
        name: "CSwiftOmniUIWinUI",
        path: "lib/SwiftOmniUI.WinUI/Sources/CSwiftOmniUIWinUI",
        cxxSettings: [.headerSearchPath("../../.projection")],
        // An SVG is handed to WinUI from memory; a zone's offset is ICU's, and the kept values stand in the
        // user's local data; a canvas draws with Direct2D and DirectWrite on a Direct3D device.
        linkerSettings: [
            .linkedLibrary("shcore"), .linkedLibrary("shlwapi"), .linkedLibrary("icu"), .linkedLibrary("shell32"),
            .linkedLibrary("ole32"), .linkedLibrary("d2d1"), .linkedLibrary("d3d11"), .linkedLibrary("dwrite"),
        ]
    ),
    .target(
        name: "SwiftOmniUIWinUI",
        dependencies: ["CSwiftOmniUIWinUI", "SwiftOmniUI", "SwiftOmniUIHost"],
        path: "lib/SwiftOmniUI.WinUI/Sources/SwiftOmniUIWinUI",
        swiftSettings: settings
    ),
    // WinUI's WebView2, C++/WinRT behind C functions.
    .target(
        name: "CWebViewWinUI",
        path: "lib/Backends/WebView.WinUI/Relay",
        cxxSettings: [.unsafeFlags(["-I", Context.packageDirectory + "/lib/SwiftOmniUI.WinUI/.projection"])],
        linkerSettings: [.linkedLibrary("shcore"), .linkedLibrary("shlwapi")]
    ),
    .target(
        name: "SwiftOmniUIWebViewWinUI",
        dependencies: ["CWebViewWinUI", "SwiftOmniUI", "SwiftOmniUIHost", "SwiftOmniUIWinUI"],
        path: "lib/Backends/WebView.WinUI/Sources/SwiftOmniUIWebViewWinUI",
        swiftSettings: settings + [.define("WINUI")]
    ),
]
#endif

let package = Package(
    name: "SwiftOmniUI",
    // macOS 15 is the floor SCE (Logorythia) deploys to; iOS/Mac Catalyst stay
    // at 26, the releases upstream builds and tests against.
    platforms: [
        .iOS(.v26),
        .macCatalyst(.v26),
        .macOS(.v15),
    ],
    products: products,
    dependencies: [
        // The JsonData model layer's checkout: Packges/JsonData beside Packges/SwiftOmniUI
        // locally, zxs20/JsonData beside zxs20/SwiftOmniUI on Windows.
        .package(url: "https://github.com/zxss702/JsonData.git", branch: "main"),
    ],
    targets: targets,
    cxxLanguageStandard: .cxx20
)
