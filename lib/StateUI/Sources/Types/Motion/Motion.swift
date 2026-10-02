// SPDX-FileCopyrightText: 2026 Paweł Krzywdziński and Contributors
// SPDX-License-Identifier: Apache-2.0

// How a value animates when it changes: one vocabulary for the application, an
// element, a state and a single write.
// Design: docs/design/types/animation.md#one-vocabulary-in-four-places

/// How a value animates when it changes.
///
/// A change animates by default - assign a state and the control animates to
/// the new value - and a animation says how:
///
///     VStack { … }.animation(.spring(response: 260))
///
///     try await $fade.journey.move(to: 0.1, .eased(400, .cubicOut))
///
/// `.none` applies a change at once. `.custom` hands the animation to an
/// engine of your own. `.eased` and `.spring` name a timing law and its
/// numbers.
///
/// Design: docs/design/types/animation.md#two-laws
public struct Animation: Equatable, Sendable {
    /// Which timing law a animation follows.
    public enum Law: Int32, Sendable {
        /// A stated duration on a stated curve.
        case eased = 0

        /// A mass on a spring - no duration, only a response.
        case spring = 1
    }

    /// The timing law this animation follows.
    public let law: Law

    /// Milliseconds: how long an eased animation takes, or a spring's response.
    public let millis: UInt32

    /// The curve an eased animation follows.
    public let curve: Easing

    /// A spring's damping; 0 for an eased animation.
    public let factor: Double

    /// Whether this animation is the one its element resolves to rather than one
    /// of its own.
    public let isInherited: Bool

    /// Whether an application engine animates the value instead of the host;
    /// see `custom`.
    public let isCustom: Bool

    /// The animation the element resolves to: its own, else the application's,
    /// else `standard`.
    ///
    /// What a write means when it names no animation, so a plain assignment and
    /// `move(to:)` agree about the animation and differ only in being awaited.
    public static let inherited = Animation(
        law: .eased, millis: 0, curve: .cubicOut, factor: 0, isInherited: true, isCustom: false)

    /// No animation: the change is applied at once.
    public static let none = Animation(
        law: .eased, millis: 0, curve: .cubicOut, factor: 0, isInherited: false, isCustom: false)

    /// The animation is yours: a write moves only the destination, the host
    /// animates nothing, and an engine of your own writes where the value is
    /// and how fast it is going, frame by frame, reading the destination back.
    ///
    ///     @State(animation: .custom) private var ball = 0.0
    ///
    ///     ColorPicker()
    ///         .offset(y: $ball)
    ///         .engine(following: $ball) { cycle in
    ///             let journey = $ball.journey
    ///             let pull = (journey.destination - journey.value) * 0.2
    ///             journey.velocity += pull
    ///             journey.value += journey.velocity * cycle.elapsed / 1000
    ///             return abs(pull) > 0.01 ? .again : .wait
    ///         }
    ///
    /// Unlike `.none`, a write changes only where the value is going; where it
    /// is stays put until the engine moves it. Declare it on the state, since
    /// which side animates a state is fixed when the state first reaches the
    /// host.
    ///
    /// Design: docs/design/types/animation.md#custom-animates-in-an-engine
    public static let custom = Animation(
        law: .eased, millis: 0, curve: .cubicOut, factor: 0, isInherited: false, isCustom: true)

    /// An animation of a stated duration on a stated curve.
    ///
    ///     .animation(.eased(400, .cubicOut))
    ///
    /// It takes the stated time whatever the distance: right for something
    /// whose distance is known, such as a fade, a page sliding in, or a card
    /// turning over.
    ///
    /// - Parameters:
    ///   - length: how long it takes, in milliseconds.
    ///   - curve: how it spends that time. `.cubicOut` arrives gently, which is
    ///     what almost everything on screen wants.
    /// - Returns: the animation.
    public static func eased(_ length: UInt, _ curve: Easing = .cubicOut) -> Animation {
        Animation(
            law: .eased,
            millis: UInt32(truncatingIfNeeded: length),
            curve: curve,
            factor: 0,
            isInherited: false,
            isCustom: false)
    }

    /// A mass on a spring, which answers a change rather than timing it.
    ///
    ///     .animation(.spring(response: 260))
    ///
    /// It has no duration: a spring settles when it is done, and one whose
    /// destination changes mid-animation carries on from the speed it had.
    /// That makes it right for anything the user can interrupt - a card being
    /// dragged, a value still being chosen.
    ///
    /// - Parameters:
    ///   - response: how quickly it answers, in milliseconds. Smaller is
    ///     snappier.
    ///   - damping: 1 comes to rest without overshooting; below 1 overshoots
    ///     and oscillates, which is rarely what a user expects.
    /// - Returns: the animation.
    public static func spring(response: UInt = 300, damping: Double = 1) -> Animation {
        Animation(
            law: .spring,
            millis: UInt32(truncatingIfNeeded: max(response, 1)),
            curve: .linear,
            factor: max(damping, 0.05),
            isInherited: false,
            isCustom: false)
    }

    /// Whether this animation animates nothing - the value simply arrives.
    var isNothing: Bool {
        !isInherited && !isCustom && law == .eased && millis == 0
    }

    /// This animation, or `fallback` where this is the inherited one.
    func resolved(against fallback: Animation) -> Animation {
        isInherited ? fallback : self
    }

    /// The default animation: 200 milliseconds on `.cubicOut`, for ordinary
    /// changes and a scroller's landing.
    public static let standard = Animation.eased(200, .cubicOut)
}
