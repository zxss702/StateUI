// SPDX-FileCopyrightText: 2026 Paweł Krzywdziński and Contributors
// SPDX-License-Identifier: Apache-2.0

/// The builder an `App`'s `body` is written with: the scenes of the body, or
/// an `if` choosing between two.
///
///     var body: some Scene {
///         Window("欢迎页", id: "welcome") { WelcomePage() }
///         WindowGroup(for: URL.self) { $url in EditorWindow(url: url) }
///     }
///
/// SwiftUI reads each entry a scene of its own; SwiftOmniUI builds one scene
/// of them - the first to declare a main window supplies it, and every
/// scene's groups, commands and environments stand beside it.
@resultBuilder
public enum SceneBuilder {
    /// A scene passes through as itself.
    public static func buildExpression<Content: Scene>(_ expression: Content) -> Content {
        expression
    }

    /// The one scene the body is.
    public static func buildBlock<Content: Scene>(_ scene: Content) -> Content {
        scene
    }

    /// The scenes of a body of two.
    public static func buildBlock<First: Scene, Second: Scene>(
        _ first: First, _ second: Second
    ) -> TupleScene {
        let pair = (Carry(first), Carry(second))
        return MainActor.assumeIsolated {
            Carry(TupleScene(scenes: [pair.0.value, pair.1.value]))
        }.value
    }

    /// The scenes of a body of three.
    public static func buildBlock<First: Scene, Second: Scene, Third: Scene>(
        _ first: First, _ second: Second, _ third: Third
    ) -> TupleScene {
        let trio = (Carry(first), Carry(second), Carry(third))
        return MainActor.assumeIsolated {
            Carry(TupleScene(scenes: [trio.0.value, trio.1.value, trio.2.value]))
        }.value
    }

    /// The scenes of a body of four.
    public static func buildBlock<First: Scene, Second: Scene, Third: Scene, Fourth: Scene>(
        _ first: First, _ second: Second, _ third: Third, _ fourth: Fourth
    ) -> TupleScene {
        let all = (Carry(first), Carry(second), Carry(third), Carry(fourth))
        return MainActor.assumeIsolated {
            Carry(TupleScene(scenes: [all.0.value, all.1.value, all.2.value, all.3.value]))
        }.value
    }

    /// An `if` branch's scene.
    public static func buildEither<Content: Scene>(first scene: Content) -> ConditionalScene {
        let carried = Carry(scene)
        return MainActor.assumeIsolated { Carry(ConditionalScene(wrapped: carried.value)) }.value
    }

    /// An `else` branch's scene.
    public static func buildEither<Content: Scene>(second scene: Content) -> ConditionalScene {
        let carried = Carry(scene)
        return MainActor.assumeIsolated { Carry(ConditionalScene(wrapped: carried.value)) }.value
    }
}

/// One of two scenes an `if` in an app's `body` chose: whichever stands is the
/// scene, the other is not there.
public struct ConditionalScene: Scene {
    /// The branch taken.
    let wrapped: any Scene

    /// The windows of whichever scene was chosen.
    public var windows: Windows { wrapped.windows }
}

/// The several scenes an app's `body` declares, as one: the first scene's
/// main window is the scene's own, and every scene's groups - so its kinds
/// of window - answer `openWindow` together.
///
/// Scene-level asks - `defaultSize`, `commands`, the environments offered -
/// merge the same way: the first scene to ask a thing stands.
public struct TupleScene: Scene {
    /// The scenes, in the order the body wrote them.
    let scenes: [any Scene]

    /// The windows of every scene together.
    public var windows: Windows {
        var groups: [WindowGroup] = []
        var main: WindowScene?
        var environments: [(key: ObjectIdentifier, object: AnyObject)] = []
        var environmentEdits: [(inout EnvironmentValues) -> Void] = []
        var commands: [any Commands] = []
        var defaultSize: (width: Double, height: Double)? = nil
        var defaultPosition: UnitPoint? = nil
        var resizability: WindowResizability? = nil

        for scene in scenes {
            // An object's `.environment` wrapper hands its object down as the
            // merge goes by it.
            var scene = scene
            while let offered = scene as? OfferingScene {
                environments.append((key: offered.key, object: offered.object))
                scene = offered.base
            }

            let windows = scene.windows
            if main == nil { main = windows.main }
            groups += windows.groups
            environments += windows.environments
            environmentEdits += windows.environmentEdits
            commands += windows.commands
            defaultSize = defaultSize ?? windows.defaultSize
            defaultPosition = defaultPosition ?? windows.defaultPosition
            resizability = resizability ?? windows.resizability
        }

        var merged = Windows(groups: groups, main: main)
        merged.environments = environments
        merged.environmentEdits = environmentEdits
        merged.commands = commands
        merged.defaultSize = defaultSize
        merged.defaultPosition = defaultPosition
        merged.resizability = resizability
        return merged
    }
}
