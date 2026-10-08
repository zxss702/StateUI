// SPDX-FileCopyrightText: 2026 Paweł Krzywdziński and Contributors
// SPDX-License-Identifier: Apache-2.0

/// A value walked out of `MainActor.assumeIsolated`, which requires its result
/// be `Sendable`. The callers this serves already stand on the UI thread - the
/// box only carries the value past the signature, never across a real thread.
struct Carry<Value>: @unchecked Sendable {
    let value: Value

    init(_ value: Value) {
        self.value = value
    }
}

/// Runs `body` on the UI thread: the callers this serves - result builders
/// and scene plumbing - always stand there already, the `assumeIsolated`
/// only tells the type system so. Both directions ride `Carry`, since what
/// goes in and comes out is not `Sendable`.
@discardableResult
func onMain<Value>(_ body: @MainActor () -> Value) -> Value {
    return MainActor.assumeIsolated { Carry(body()) }.value
}
