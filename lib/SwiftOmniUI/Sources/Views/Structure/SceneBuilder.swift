// SPDX-FileCopyrightText: 2026 Paweł Krzywdziński and Contributors
// SPDX-License-Identifier: Apache-2.0

/// The builder an `App`'s `body` is written with: one scene, or an `if`
/// choosing between two.
///
///     var body: some Scene { Window { MainPage() } }
///
///     var body: some Scene {
///         if restored { EditorScene() } else { OnboardingScene() }
///     }
///
/// An application's body is one scene - the windows beside its main one are a
/// scene's own `Windows`, not more entries here.
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

    /// An `if` branch's scene.
    public static func buildEither<Content: Scene>(first scene: Content) -> ConditionalScene {
        ConditionalScene(wrapped: scene)
    }

    /// An `else` branch's scene.
    public static func buildEither<Content: Scene>(second scene: Content) -> ConditionalScene {
        ConditionalScene(wrapped: scene)
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
