// swift-tools-version:6.4
import PackageDescription

// One package owns every SwiftOmniUI module. Internal dependencies are targets;
// ordinary library products expose those modules to applications.
let settings: [SwiftSetting] = [.enableUpcomingFeature("NonisolatedNonsendingByDefault")]
let host = ["AppKit", "UIKit", "Android", "WinUI", "GTK", "Web"]
    .first { $0.lowercased() == Context.environment["SWIFTOMNIUI_HOST"] }
let selectedHost = host
var products: [Product] = [
    .library(name: "SwiftOmniUI", targets: ["SwiftOmniUI"]),
    .library(name: "SwiftOmniUIHost", targets: ["SwiftOmniUIHost"]),
    .library(name: "SwiftOmniUIFoundation", targets: ["SwiftOmniUIFoundation"]),
    .library(name: "SwiftOmniUIJsonData", targets: ["SwiftOmniUIJsonData"]),
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
            swiftSettings: [.enableUpcomingFeature("NonisolatedNonsendingByDefault")]
        ),
        .target(
            name: "SwiftOmniUIFoundation",
            dependencies: ["SwiftOmniUI"],
            path: "lib/SwiftOmniUI.Foundation/Sources",
            swiftSettings: [.enableUpcomingFeature("NonisolatedNonsendingByDefault")]
        ),
        .target(
            name: "SwiftOmniUIJsonData",
            dependencies: [
                "SwiftOmniUI",
                // The same ordinary JsonData product applications consume.
                .product(name: "JsonData", package: "JsonData"),
            ],
            path: "lib/SwiftOmniUI.JsonData/Sources",
            swiftSettings: [.enableUpcomingFeature("NonisolatedNonsendingByDefault")]
        ),
        .target(
            name: "SwiftOmniUIConformance",
            dependencies: ["SwiftOmniUI",
                "SwiftOmniUIHost"],
            path: "lib/SwiftOmniUI.Conformance/Sources",
            swiftSettings: [.enableUpcomingFeature("NonisolatedNonsendingByDefault")]
        ),
        .target(
            name: "SwiftOmniUIHead",
            dependencies: host.map { [.target(name: "SwiftOmniUI\($0)")] } ?? [],
            path: "lib/SwiftOmniUI.Head/Sources",
            swiftSettings: [.enableUpcomingFeature("NonisolatedNonsendingByDefault")]
                + (host.map { [.define($0.uppercased())] } ?? []),
            // A WinUI head is a windowed application: started by itself it opens no console, and started from one it
            // writes there. A Web head's module exports its function table, through which the page calls the host
            // back, and its stack is the main thread's on macOS and Linux, 8 MB, below its data, so running out of
            // it stops the program rather than overwriting what lies beyond (docs/design/platforms/web/runtime.md).
            linkerSettings: host == "WinUI"
                ? [.unsafeFlags(["-Xlinker", "/SUBSYSTEM:WINDOWS", "-Xlinker", "/ENTRY:mainCRTStartup"])]
                : host == "Web"
                ? [.unsafeFlags(["-Xlinker", "--export-table", "-Xlinker", "--stack-first",
                    "-Xlinker", "-z", "-Xlinker", "stack-size=8388608", "-Xlinker", "--global-base=8388608"]),
                   // A release page carries no debugging information: 14.5 MB of HelloWorld rather than 23.7.
                   .unsafeFlags(["-Xlinker", "--strip-debug"], .when(configuration: .release))]
                : []
        ),
]

// Device and Web suites use their own platform runners.
if selectedHost != "UIKit" && selectedHost != "Android" && selectedHost != "Web" {
    targets += [
        .testTarget(name: "SwiftOmniUITests", dependencies: ["SwiftOmniUI"],
            path: "lib/SwiftOmniUI/Tests", swiftSettings: settings),
        .testTarget(
            name: "SwiftOmniUIHostTests",
            dependencies: ["SwiftOmniUIHost", "SwiftOmniUI"],
            path: "lib/SwiftOmniUI.Host/Tests",
            swiftSettings: [.enableUpcomingFeature("NonisolatedNonsendingByDefault")]
        ),
        .testTarget(
            name: "SwiftOmniUIFoundationTests",
            dependencies: ["SwiftOmniUIFoundation"],
            path: "lib/SwiftOmniUI.Foundation/Tests",
            swiftSettings: [.enableUpcomingFeature("NonisolatedNonsendingByDefault")]
        ),
        .testTarget(
            name: "SwiftOmniUIJsonDataTests",
            dependencies: ["SwiftOmniUIJsonData"],
            path: "lib/SwiftOmniUI.JsonData/Tests",
            swiftSettings: [.enableUpcomingFeature("NonisolatedNonsendingByDefault")]
        ),
        .testTarget(
            name: "SwiftOmniUIConformanceTests",
            dependencies: ["SwiftOmniUIConformance", "SwiftOmniUI",
                "SwiftOmniUIHost"],
            path: "lib/SwiftOmniUI.Conformance/Tests",
            swiftSettings: [.enableUpcomingFeature("NonisolatedNonsendingByDefault")]
        ),
    ]
}

switch selectedHost {
case "AppKit"?:
    products += [
        .library(name: "SwiftOmniUIAppKit", targets: ["SwiftOmniUIAppKit"]),
    ]
    targets += [
        .target(
            name: "SwiftOmniUIAppKit",
            dependencies: ["SwiftOmniUI",
                "SwiftOmniUIHost"],
            path: "lib/SwiftOmniUI.AppKit/Sources",
            swiftSettings: [.enableUpcomingFeature("NonisolatedNonsendingByDefault")],
            linkerSettings: [.linkedFramework("AppKit")]
        ),
        .testTarget(
            name: "SwiftOmniUIAppKitTests",
            dependencies: [
                "SwiftOmniUIAppKit",
                "SwiftOmniUI",
                "SwiftOmniUIHost",
                "SwiftOmniUIConformance",
            ],
            path: "lib/SwiftOmniUI.AppKit/Tests",
            exclude: ["Resources"],
            swiftSettings: [.enableUpcomingFeature("NonisolatedNonsendingByDefault")],
            linkerSettings: [.linkedFramework("AppKit")]
        ),
    ]
case "GTK"?:
    products += [
        .library(name: "SwiftOmniUIGTK", targets: ["SwiftOmniUIGTK"]),
        .library(name: "SwiftOmniUIWebViewGTK", targets: ["SwiftOmniUIWebViewGTK"]),
    ]
    targets += [
        .systemLibrary(name: "CSwiftOmniUIGTK", path: "lib/SwiftOmniUI.GTK/Sources/CSwiftOmniUIGTK", pkgConfig: "libadwaita-1"),
        .target(
            name: "SwiftOmniUIGTK",
            dependencies: ["CSwiftOmniUIGTK", "SwiftOmniUI",
                "SwiftOmniUIHost"],
            path: "lib/SwiftOmniUI.GTK/Sources/SwiftOmniUIGTK",
            resources: [.copy("Resources/Icons")],
            swiftSettings: [.enableUpcomingFeature("NonisolatedNonsendingByDefault")]
        ),
        .testTarget(
            name: "SwiftOmniUIGTKTests",
            dependencies: [
                "SwiftOmniUIGTK", "CSwiftOmniUIGTK", "SwiftOmniUI",
                "SwiftOmniUIHost",
                "SwiftOmniUIConformance",
                "SwiftOmniUIWebViewGTK",
            ],
            path: "lib/SwiftOmniUI.GTK/Tests",
            exclude: ["Resources"],
            swiftSettings: [.enableUpcomingFeature("NonisolatedNonsendingByDefault")]
        ),
        .systemLibrary(name: "CWebKitGTK", path: "lib/Backends/WebView.GTK/Sources/CWebKitGTK", pkgConfig: "webkitgtk-6.0"),
        .target(
            name: "SwiftOmniUIWebViewGTK",
            dependencies: [
                "CWebKitGTK",
                "SwiftOmniUIHost",
                "SwiftOmniUIGTK",
                "SwiftOmniUI",
            ],
            path: "lib/Backends/WebView.GTK/Sources/SwiftOmniUIWebViewGTK", swiftSettings: settings + [.define("GTK")]),
    ]
case "WinUI"?:
    products += [
        .library(name: "SwiftOmniUIWinUI", targets: ["SwiftOmniUIWinUI"]),
        .library(name: "SwiftOmniUIWebViewWinUI", targets: ["SwiftOmniUIWebViewWinUI"]),
    ]
    targets += [
        .target(
            name: "CSwiftOmniUIWinUI",
            path: "lib/SwiftOmniUI.WinUI/Sources/CSwiftOmniUIWinUI",
            cxxSettings: [.headerSearchPath("../../.projection")],
            // An SVG is handed to WinUI from memory; a zone's offset is ICU's, and the kept values stand in the
            // user's local data; a canvas draws with Direct2D and DirectWrite on a Direct3D device.
            linkerSettings: [
                .linkedLibrary("shcore"), .linkedLibrary("shlwapi"), .linkedLibrary("icu"), .linkedLibrary("shell32"),
                .linkedLibrary("ole32"), .linkedLibrary("d2d1"), .linkedLibrary("d3d11"), .linkedLibrary("dwrite"),
                .linkedLibrary("windowscodecs"),
            ]
        ),
        .target(
            name: "SwiftOmniUIWinUI",
            dependencies: ["CSwiftOmniUIWinUI", "SwiftOmniUI",
                "SwiftOmniUIHost"],
            path: "lib/SwiftOmniUI.WinUI/Sources/SwiftOmniUIWinUI",
            swiftSettings: [.enableUpcomingFeature("NonisolatedNonsendingByDefault")]
        ),
        .testTarget(
            name: "SwiftOmniUIWinUITests",
            dependencies: [
                "SwiftOmniUIWinUI", "CSwiftOmniUIWinUI", "SwiftOmniUI",
                "SwiftOmniUIHost",
                "SwiftOmniUIConformance",
            ],
            path: "lib/SwiftOmniUI.WinUI/Tests",
            // The pictures a test shows, read from where they stand rather than bundled.
            exclude: ["Resources"],
            swiftSettings: [.enableUpcomingFeature("NonisolatedNonsendingByDefault")]
        ),
        .target(
            name: "CWebViewWinUI",
            path: "lib/Backends/WebView.WinUI/Relay",
            cxxSettings: [.unsafeFlags(["-I", Context.packageDirectory + "/lib/SwiftOmniUI.WinUI/.projection"])],
            linkerSettings: [.linkedLibrary("shcore"), .linkedLibrary("shlwapi")]
        ),
        .target(
            name: "SwiftOmniUIWebViewWinUI",
            dependencies: [
                "CWebViewWinUI",
                "SwiftOmniUIHost",
                "SwiftOmniUIWinUI",
                "SwiftOmniUI",
            ],
            path: "lib/Backends/WebView.WinUI/Sources/SwiftOmniUIWebViewWinUI", swiftSettings: settings + [.define("WINUI")]),
    ]
case "UIKit"?:
    products += [
        .library(name: "SwiftOmniUIUIKit", targets: ["SwiftOmniUIUIKit"]),
        .executable(name: "SwiftOmniUIUIKitTests", targets: ["SwiftOmniUIUIKitTests"]),
    ]
    targets += [
        .target(
            name: "SwiftOmniUIUIKit",
            dependencies: ["SwiftOmniUI",
                "SwiftOmniUIHost"],
            path: "lib/SwiftOmniUI.UIKit/Sources",
            swiftSettings: [.enableUpcomingFeature("NonisolatedNonsendingByDefault")],
            linkerSettings: [.linkedFramework("UIKit")]
        ),
        .executableTarget(
            name: "SwiftOmniUIUIKitTests",
            dependencies: [
                "SwiftOmniUI",
                "SwiftOmniUIUIKit",
                "SwiftOmniUIHost",
                "SwiftOmniUIConformance",
            ],
            path: "lib/SwiftOmniUI.UIKit/Tests/Sources",
            swiftSettings: [.enableUpcomingFeature("NonisolatedNonsendingByDefault")],
            linkerSettings: [.linkedFramework("XCTest"), .linkedFramework("UIKit")]
        ),
    ]
case "Android"?:
    products += [
        .library(name: "SwiftOmniUIAndroid", targets: ["SwiftOmniUIAndroid"]),
        // The APK loads this final test runner through JNI.
        .library(name: "SwiftOmniUIAndroidTests", type: .dynamic, targets: ["SwiftOmniUIAndroidTests"]),
    ]
    targets += [
        .target(
            name: "CSwiftOmniUIAndroid",
            path: "lib/SwiftOmniUI.Android/Sources/CSwiftOmniUIAndroid",
            linkerSettings: [.linkedLibrary("android"), .linkedLibrary("log")]
        ),
        .target(
            name: "SwiftOmniUIAndroid",
            dependencies: ["CSwiftOmniUIAndroid", "SwiftOmniUI",
                "SwiftOmniUIHost"],
            path: "lib/SwiftOmniUI.Android/Sources/SwiftOmniUIAndroid",
            swiftSettings: [.enableUpcomingFeature("NonisolatedNonsendingByDefault")]
        ),
        .target(
            name: "SwiftOmniUIAndroidTests",
            dependencies: [
                "SwiftOmniUI",
                "SwiftOmniUIAndroid",
                "SwiftOmniUIHost",
                "SwiftOmniUIConformance",
            ],
            path: "lib/SwiftOmniUI.Android/Tests/Sources",
            swiftSettings: [.enableUpcomingFeature("NonisolatedNonsendingByDefault")]
        ),
    ]
case "Web"?:
    products += [
        .library(name: "SwiftOmniUIWeb", targets: ["SwiftOmniUIWeb"]),
    ]
    targets += [
        .systemLibrary(name: "CSwiftOmniUIWeb", path: "lib/SwiftOmniUI.Web/Sources/CSwiftOmniUIWeb"),
        .target(
            name: "SwiftOmniUIWeb",
            dependencies: ["CSwiftOmniUIWeb", "SwiftOmniUI",
                "SwiftOmniUIHost"],
            path: "lib/SwiftOmniUI.Web/Sources/SwiftOmniUIWeb",
            swiftSettings: [.enableUpcomingFeature("NonisolatedNonsendingByDefault")]
        ),
        .systemLibrary(name: "CWebTesting", path: "lib/SwiftOmniUI.Web/Testing/Sources/CWebTesting"),
        .testTarget(
            name: "SwiftOmniUIWebTests",
            dependencies: [
                "CWebTesting", "SwiftOmniUIWeb",
                "SwiftOmniUIHost", "SwiftOmniUI",
                "SwiftOmniUIConformance",
            ],
            path: "lib/SwiftOmniUI.Web/Testing/Tests",
            exclude: ["Resources"],
            swiftSettings: [.enableUpcomingFeature("NonisolatedNonsendingByDefault")],
            // The stack a Web head links with: 8 MB, first in memory (docs/design/platforms/web/runtime.md#the-stack).
            linkerSettings: [.unsafeFlags([
                "-Xlinker", "--export-table", "-Xlinker", "--stack-first",
                "-Xlinker", "-z", "-Xlinker", "stack-size=8388608", "-Xlinker", "--global-base=8388608",
            ])]
        ),
    ]
default:
    break
}

let package = Package(
    name: "SwiftOmniUIRoot",
    platforms: [.iOS(.v26), .macCatalyst(.v26), .macOS(.v15)],
    products: products,
    dependencies: [.package(url: "https://github.com/zxss702/JsonData.git", branch: "main")],
    targets: targets,
    cxxLanguageStandard: .cxx20
)
