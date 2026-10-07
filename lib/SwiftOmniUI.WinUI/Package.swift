// swift-tools-version:6.4
import PackageDescription

// The WinUI 3 host: Swift in the application's process, reading the typed
// patch and calling WinUI through a C++/WinRT relay behind a C ABI. A sibling
// package, as the AppKit and Android Views hosts are, so the one dynamic
// SwiftOmniUI runtime is linked into the application rather than copied into a
// second library in the same process. It builds on Windows alone:
// .scripts/WinUI/tools.ps1 generates the C++/WinRT projection the relay
// includes, into .projection/, and lays the Windows App SDK beside what is built.
let package = Package(
    name: "SwiftOmniUIWinUI",
    products: [
        .library(name: "SwiftOmniUIWinUI", type: .dynamic, targets: ["SwiftOmniUIWinUI"]),
    ],
    dependencies: [
        .package(name: "SwiftOmniUIRoot", path: "../.."),
        .package(name: "SwiftOmniUIHost", path: "../SwiftOmniUI.Host"),
        .package(name: "SwiftOmniUIConformance", path: "../SwiftOmniUI.Conformance"),
    ],
    targets: [
        // The relay: WinUI's subclasses, its events, the doorbell's post and the
        // frame clock, behind the C functions its header declares.
        .target(
            name: "CSwiftOmniUIWinUI",
            path: "Sources/CSwiftOmniUIWinUI",
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
            dependencies: ["CSwiftOmniUIWinUI", .product(name: "SwiftOmniUI", package: "SwiftOmniUIRoot"),
                .product(name: "SwiftOmniUIHost", package: "SwiftOmniUIHost")],
            path: "Sources/SwiftOmniUIWinUI",
            swiftSettings: [.enableUpcomingFeature("NonisolatedNonsendingByDefault")]
        ),
        .testTarget(
            name: "SwiftOmniUIWinUITests",
            dependencies: [
                "SwiftOmniUIWinUI", "CSwiftOmniUIWinUI", .product(name: "SwiftOmniUI", package: "SwiftOmniUIRoot"),
                .product(name: "SwiftOmniUIHost", package: "SwiftOmniUIHost"),
                .product(name: "SwiftOmniUIConformance", package: "SwiftOmniUIConformance"),
            ],
            path: "Tests",
            // The pictures a test shows, read from where they stand rather than bundled.
            exclude: ["Resources"],
            swiftSettings: [.enableUpcomingFeature("NonisolatedNonsendingByDefault")]
        ),
    ],
    cxxLanguageStandard: .cxx20
)
