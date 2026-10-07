[![Core macOS](https://github.com/zxss702/SwiftOmniUI/actions/workflows/build-mac.yml/badge.svg?branch=main)](https://github.com/zxss702/SwiftOmniUI/actions/workflows/build-mac.yml?query=branch%3Amain)
[![Core Linux](https://github.com/zxss702/SwiftOmniUI/actions/workflows/build-linux.yml/badge.svg?branch=main)](https://github.com/zxss702/SwiftOmniUI/actions/workflows/build-linux.yml?query=branch%3Amain)
[![Core Windows](https://github.com/zxss702/SwiftOmniUI/actions/workflows/build-windows.yml/badge.svg?branch=main)](https://github.com/zxss702/SwiftOmniUI/actions/workflows/build-windows.yml?query=branch%3Amain)\
[![AppKit](https://github.com/zxss702/SwiftOmniUI/actions/workflows/appkit.yml/badge.svg?branch=main)](https://github.com/zxss702/SwiftOmniUI/actions/workflows/appkit.yml?query=branch%3Amain)
[![UIKit](https://github.com/zxss702/SwiftOmniUI/actions/workflows/uikit.yml/badge.svg?branch=main)](https://github.com/zxss702/SwiftOmniUI/actions/workflows/uikit.yml?query=branch%3Amain)
[![Android](https://github.com/zxss702/SwiftOmniUI/actions/workflows/android.yml/badge.svg?branch=main)](https://github.com/zxss702/SwiftOmniUI/actions/workflows/android.yml?query=branch%3Amain)
[![WinUI](https://github.com/zxss702/SwiftOmniUI/actions/workflows/winui.yml/badge.svg?branch=main)](https://github.com/zxss702/SwiftOmniUI/actions/workflows/winui.yml?query=branch%3Amain)
[![GTK](https://github.com/zxss702/SwiftOmniUI/actions/workflows/gtk.yml/badge.svg?branch=main)](https://github.com/zxss702/SwiftOmniUI/actions/workflows/gtk.yml?query=branch%3Amain)
# SwiftOmniUI

 **Native interfaces, written in Swift.**
> SwiftOmniUI describes an application's interface in Swift. Swift owns the UI tree,
identity, state, diffing, and motion; a thin host applies sparse patches to
controls from its platform toolkit.

Every host is Swift, in the application's own process, and all six hosts are
active on the same host contract: AppKit, UIKit, Android Views, WinUI 3, GTK 4
with libadwaita, and Web (DOM/CSS over WebAssembly). What each realizes,
element by element and member by member, is the
[platform contract](docs/platform-contract.md), rendered from each host's own
test run.

| AppKit | UIKit | Android Views | WinUI 3 | GTK 4 | Web |
| :---: | :---: | :---: | :---: | :---: | :---: |
| ☑️ | ☑️ | ☑️ | ☑️ | ☑️ | ☑️ |

The public Swift API is a **SwiftUI-compatible subset**: anything SwiftUI has
a model for keeps SwiftUI's name and semantics. Where a platform-neutral
application needs what SwiftUI does not model - window sessions, environment
keys such as `application.persistentKeys`, host registration - the addition
extends the same conceptual model rather than inventing a dialect, and
vocabulary that has no SwiftUI equivalent stays internal or `@_spi(Host)`.
SwiftOmniUI is proposed by
[Huaxia Xufu (Beijing) Technology Co., Ltd.](https://github.com/zxss702/SwiftOmniUI)
(华夏旭府（北京）科技有限公司), and is derived from upstream
[StateUI](https://github.com/idexus/StateUI) by Paweł Krzywdziński and
contributors; upstream work comes in as reviewed cherry-picks, never a
wholesale merge.

## In Action

<p>
  <img src="docs/assets/winui.jpg" alt="The Gallery's home page on WinUI 3" width="75.7%"
  ><img src="docs/assets/uikit.jpg" alt="The Gallery's home page on UIKit, on an iPhone" width="24.1%">
</p>
<p>
  <img src="docs/assets/gtk.jpg" alt="The Gallery's Grid sample on GTK 4 with libadwaita" width="74.3%"
  ><img src="docs/assets/android.jpg" alt="The Gallery's Grid sample on Android Views" width="25.5%">
</p>

The same Gallery - one Swift module - on WinUI 3, UIKit, GTK 4 and Android
Views: each host draws it with its own toolkit's controls, its window chrome
and its navigation, while the pages, the state and the samples are the
application's, written once.

The AppKit host draws it with macOS controls, in the same process as the
application module - here the Gallery's Metal sample: the cube
is an `MTKView` the application registers with the host, and its size, colour
and spin are described from SwiftOmniUI. The edge is handed over as a state, so
dragging the slider rebuilds nothing:

<video src="https://github.com/user-attachments/assets/05ef0718-b3b5-4f67-8c66-7a9c9b1d2ba2" controls muted loop width="960" height="540" poster="docs/assets/appkit-poster.png">
  <a href="docs/assets/appkit.mp4"><img src="docs/assets/appkit-poster.png" alt="The Gallery's Metal sample on the AppKit host" width="960" height="540"></a>
</video>

## In Code

```swift
struct CounterPage: View {
    @State private var count = 0

    var body: some View {
        VStack {
            Text("Tapped \(count) times")
            Button("Tap me") { count += 1 }
        }
    }
}
```

SwiftOmniUI has one state declaration and two reactive paths:

- reading a state rebuilds only the body that read it;
- handing a binding to a control or property lets the host update it without
  rebuilding that body.

`Journey` belongs to the same state and carries its current value, destination,
velocity, and motion. A host with verified motion support animates compatible
property changes on the platform display clock; an unverified or unsupported
pair snaps to its destination.

SwiftOmniUI is under active development. Until a 1.0 release, the public Swift API
and host contract may change together when native evidence reveals a clearer
cross-platform model. The handbook and platform matrix describe the contract
that is usable now.

## Documentation

- [SwiftOmniUI handbook](docs/README.md) — the complete guide to applications,
  state, layout, controls, interaction, concurrency, and native hosts.
- [Architecture](docs/concepts/architecture.md) — state, reactivity, Journey, motion,
  and application sessions.
- [Host contract](docs/internals/host-contract.md) — `HostPatch`, ownership, identity,
  lifetime, and native adapter rules.
- [Platform contract](docs/platform-contract.md) — the control, property, and
  event inventory with verified host coverage.
- [Control dictionary](docs/controls/README.md) — every control and part of an
  application's structure, member by member, with a mark per platform.
- [SwiftOmniUI core](docs/internals/core.md) — the library every application and host
  links, folder by folder, and the typed boundary a host reads.
- [Host layer](docs/internals/host-layer.md) — the Swift every host runs on, module by
  module, and what each host provides.
- [AppKit host](docs/hosts/appkit.md), [UIKit host](docs/hosts/uikit.md), [Android Views host](docs/hosts/android.md), [WinUI host](docs/hosts/winui.md) and [GTK host](docs/hosts/gtk.md)
  — each host's heads, builds, debugging, and registrations.
- [Project structure and development](docs/development.md) — packages, Gallery,
  build, F5, and test commands.
- [Contributing](CONTRIBUTING.md) — rules for changing the public contract.

Public API declarations provide the focused reference beside the code.

## Quick start

SwiftOmniUI is developed and used in VS Code, through the SwiftOmniUI extension in
`lib/SwiftOmniUI.VSCode`. Build and install it from the checkout (Node.js 20 or
newer):

```bash
cd lib/SwiftOmniUI.VSCode
npm ci
npm run package
code --install-extension ../../artifacts/swiftomniui-*.vsix
```

The AppKit host needs only Xcode 27, on macOS 26 or newer. SwiftOmniUI builds
with one Swift release everywhere, Swift 6.4: Xcode 27's on macOS and the
swift.org 6.4.0 toolchain on the other platforms.

Android asks for more, and builds on macOS only:

- the Android SDK with NDK 30, for Android 9 (API 28) or newer; an NDK
  outside the Android SDK is named by `ANDROID_NDK_HOME`;
- the Swift SDK for Android 6.4.0, installed with `swift sdk install`;
- the swift.org toolchain of that SDK's build, `swift-6.4.0-RELEASE`, beside
  Xcode. Xcode's own Swift 6.4 is a different build and cannot read the SDK's
  modules; the build picks the matching toolchain by itself and names the one
  to install when none is there.

Then open the repository in VS Code:

1. Run **SwiftOmniUI: Check Toolchain** from the Command Palette. It lists what
   this machine has of the above, and what to install for the rest.
2. Choose the host in the status bar - **AppKit** or **Android** - and the
   application, **Gallery**.
3. Press **F5**. **SwiftOmniUI: Debug** builds the Gallery for that host and starts
   it under the debugger; **SwiftOmniUI: Release** runs the optimized build.
4. Run **SwiftOmniUI: Run Tests** from the Command Palette for every suite of that
   host.

[Working in VS Code](docs/getting-started.md#working-in-vs-code) covers the
extension's hosts and commands, including **SwiftOmniUI: New Application**.

From a terminal, the same builds are:

```bash
.scripts/AppKit/build-gallery-appkit.sh debug                  # the AppKit Gallery bundle
.scripts/Android/run-app.sh apps/Gallery debug emulator-5554   # the Android Gallery
.scripts/test-native.sh                                        # the Swift suites
```

## Continuous integration

Every workflow runs on pushes and pull requests to `main` and `dev`; a pull
request targets `dev`.

`Tests` runs the SwiftOmniUI, SwiftOmniUI.Host, SwiftOmniUI.AppKit, and Gallery suites on
macOS. The Windows and Linux workflows run the SwiftOmniUI and SwiftOmniUI.Host suites
on those machines, Linux the conformance runner too, and Windows the WinUI
host with every verdict held.

## License

SwiftOmniUI is licensed under the Apache License 2.0. See [LICENSE](LICENSE) and
[NOTICE](NOTICE). Use of the SwiftOmniUI name and mark is described in
[TRADEMARK.md](TRADEMARK.md).

SwiftOmniUI is proposed by Huaxia Xufu (Beijing) Technology Co., Ltd.
(华夏旭府（北京）科技有限公司).
