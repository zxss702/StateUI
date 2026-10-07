// SPDX-FileCopyrightText: 2026 Paweł Krzywdziński and Contributors
// SPDX-License-Identifier: Apache-2.0

// How an application is laid out in windows.
// Design: docs/design/views/pages.md#scenes

/// One session of the application: its main window, the windows it opens
/// beside it, and the state they share.
///
///     struct EditorScene: Scene {
///         @State private var document = Document()
///
///         var windows: Windows {
///             Windows {
///                 WindowGroup(.fonts) { FontsWindow() }
///             } main: {
///                 EditorWindow()
///             }
///             .environment(document)
///         }
///     }
///
/// A window is a scene of one window - what an application with nothing to
/// open beside it writes: `var body: some Scene { MainWindow() }`.
///
/// A scene holds `@State` once per session: a second *File ▸ New WindowScene* is a
/// second instance with state of its own. What every session shares belongs
/// to the `App` and reaches a scene through `.environment(_:)`.
/// Opening and closing its windows is its `SceneSession`'s, in the
/// environment of every view in it.
public protocol Scene {
    /// The scene's windows: its main one, and the groups it may open beside
    /// it. Read again when a state it read changes.
    var windows: Windows { get }
}

extension Scene {
    /// Offers an object to every window of every session of this scene,
    /// resolved by type the way `.environment` on a view is.
    ///
    ///     var body: some Scene { GalleryScene().environment(library) }
    ///
    /// A nearer `.environment()` of the same type - on `Windows`, or on a
    /// view inside - overrides it for its own branch.
    public func environment<Value: AnyObject>(_ object: Value) -> Scene {
        OfferingScene(base: self, key: ObjectIdentifier(Value.self), object: object)
    }

    /// Where the scene's windows open: `position`'s fractions across and
    /// down the screen's work area land the same fractions across and down
    /// the window - `.center` centers it, `.topLeading` its top left corner
    /// at the work area's.
    ///
    /// The scene's default: its main window opens there, and so does the
    /// window of a group that does not say its own.
    ///
    ///     var body: some Scene { EditorScene().defaultPosition(.center) }
    public func defaultPosition(_ position: UnitPoint) -> some Scene {
        PlacedScene(base: self) { $0.defaultPosition(position) }
    }

    /// Where the scene's windows open, the fractions outright.
    public func defaultPosition(x: Double, y: Double) -> some Scene {
        defaultPosition(UnitPoint(x: x, y: y))
    }

    /// Where the scene's windows open and the size they open at, in one
    /// ask - a placement's anchor, and its size where it is not `.zero`.
    /// `.automatic` asks nothing at all.
    ///
    ///     var body: some Scene { EditorScene().defaultPlacement(.topLeading) }
    public func defaultPlacement(_ placement: WindowPlacement) -> some Scene {
        PlacedScene(base: self) { $0.defaultPlacement(placement) }
    }

    /// The size the scene's windows open at, in device units - the scene's
    /// default, a group's own winning where it says one:
    ///
    ///     var body: some Scene { Window { MainPage() }.defaultSize(width: 800, height: 600) }
    public func defaultSize(width: Double, height: Double) -> some Scene {
        PlacedScene(base: self) { $0.defaultSize(width: width, height: height) }
    }

    /// The size the scene's windows open at, as one value.
    public func defaultSize(_ size: Size) -> some Scene {
        defaultSize(width: size.width, height: size.height)
    }
}

/// A scene with an object offered to everything in it.
struct OfferingScene: Scene {
    /// The scene the object is offered to.
    let base: any Scene

    /// The type the object answers for.
    let key: ObjectIdentifier

    /// The object.
    let object: AnyObject

    var windows: Windows { base.windows }
}

/// A scene whose `Windows` is edited before the tree reads it - how a
/// modifier written on `Windows` stands on a scene of any shape. The edit
/// runs as `windows` is read, inside the scene's own build, so what the
/// wrapped scene's state says is what is edited.
struct PlacedScene: Scene {
    /// The scene the edit lands on.
    let base: any Scene

    /// What the scene's windows becomes.
    let edit: (Windows) -> Windows

    var windows: Windows { edit(base.windows) }
}
