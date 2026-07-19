# Swift

Applies to PRs touching `.swift`. Sharpens [BASELINE.md](../BASELINE.md) with
the specific forms those rules take here.

## Rules

**No force-unwrap or force-cast on anything that can fail.** `!` on an optional
and `as!` are the local form of "silence the compiler". Use `guard let`,
`if let`, or `as?` with a handled failure path. Force-unwrapping is defensible
for genuinely-static resources (a bundled asset, a compile-time-known
identifier) — and when it is, it deserves a comment saying why it can't be nil.

**No `try!`.** It converts a recoverable error into a crash. Use `try` with a
`catch`, or `try?` where a nil result is genuinely handled.

**Empty `catch` blocks are findings.** So is a `catch` that only prints. Handle
it, rethrow it, or surface it to the user.

**UI work belongs on the main actor.** Anything touching AppKit/UIKit or
`@Published` state from a background context needs `@MainActor` or an explicit
hop. A background mutation of observable state is a data race, not a style
issue.

**Watch retain cycles in escaping closures.** A closure that captures `self`
strongly and outlives the call — stored handlers, timers, notification
observers, async callbacks — needs `[weak self]` unless the lifetime is
obviously bounded.

**Deprecated APIs are worth flagging when the deployment target has moved past
them.** If a PR raises the minimum OS version, the deprecated call it leaves
behind is now dead weight rather than compatibility.

## Preferences

Do not mention these.

- Prefer `guard` for early exit over nested `if let`.
- Prefer `let` over `var` — the compiler already warns.
