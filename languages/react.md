# React

Applies to PRs touching React or Next.js code (`.tsx`/`.jsx`, and hooks/components
in `.ts`/`.js`). Sharpens [BASELINE.md](../BASELINE.md) with the specific forms
those rules take here.

## Rules

**Parallelize independent async work.** Sequential `await`s for requests that
don't depend on each other cost a full round trip each. Independent fetches —
in a component, a route handler, or a server action — go through `Promise.all`
(or are kicked off before the first `await` so they run concurrently), not one
after another.

**Don't let one async component block its siblings.** In a server component
tree, `await`ing data before returning JSX blocks everything else in that
subtree, including parts of the page that don't need the data. Move the fetch
into the component that actually needs it (optionally behind a `Suspense`
boundary) instead of awaiting at the top and passing data down.

**Authenticate and authorize inside every Server Action.** A function marked
`"use server"` is a public endpoint — it can be invoked directly, not only
through the UI that calls it. A layout guard or page-level check is not
enough; the action itself must verify the session and the caller's permission
to do what it's about to do.

**No module-level mutable state for request-scoped data.** Server renders can
run concurrently in the same process. A module-level `let` written during one
render and read during another leaks data across requests — including one
user's data appearing in another user's response. Keep request-scoped values
(auth session, request headers, per-request config) in the render tree via
props or request-scoped context, not module scope.

**Don't serialize more than the client needs.** Everything passed from a
server component into a client component crosses the RSC boundary as
serialized data embedded in the response. Passing a full record so the client
component can read one field bloats the payload and — if that record carries
anything sensitive (internal IDs, other users' data, tokens) — leaks it to the
client bundle. Pass only the fields actually used.

**Never define a component inside another component's render.** Doing so
creates a new component type on every parent render, so React unmounts and
remounts it — losing state, re-running effects, resetting focus and scroll.
This shows up as input fields losing focus per keystroke, effects re-firing,
or animations restarting. Hoist the component and pass what it needs as
props.

**Derive state during render, not with an effect.** A value computable from
current props/state (e.g. `fullName` from `firstName` + `lastName`) doesn't
need its own `useState` updated in a `useEffect`. That pattern causes an extra
render and lets the derived value drift out of sync. Compute it inline during
render.

**Don't model a user action as state + effect.** If a side effect belongs to a
specific interaction (submit, click, drag), it goes in that event handler, not
behind a `useEffect` that watches a "did this happen" flag. Modeled as state,
the effect re-runs on unrelated dependency changes and can double-fire the
action.

**Use the functional form of `setState` when the update depends on the
current value.** `setItems([...items, x])` inside a `useCallback` either
forces `items` into the dependency array (recreating the callback on every
change) or goes stale if the dependency is dropped. `setItems(curr => [...curr,
x])` needs no dependency and can't go stale.

**Use a ternary, not `&&`, when the condition can be a rendered falsy value.**
`{count && <Badge/>}` renders the literal `0` when `count` is `0`. Anything
that can be `0`, `NaN`, or `''` needs `condition ? <X/> : null`.

**Handle client-only values deliberately, not with a raw mismatch.** Reading
`localStorage`, cookies, or anything else absent on the server either breaks
SSR (if read directly) or flashes the default value post-hydration (if read in
an effect). Use a synchronous inline script to set the DOM before hydration,
or `suppressHydrationWarning` for genuinely expected differences (random IDs,
locale-formatted dates). Don't reach for `suppressHydrationWarning` to silence
a real bug.

**A controlled input needs a matching `onChange`.** `<input value={x}>` with
no `onChange` renders a value the user can't edit — either wire it up or
switch to `defaultValue` for an uncontrolled field.

**Never pass unsanitized input to `dangerouslySetInnerHTML`.** Same trust
boundary as any other injection point — HTML built from user-controlled or
external data needs to go through a sanitizer first. This is XSS, not a style
nit.

**Give list items a stable, unique `key` — never the array index for a list
that can reorder, filter, or have items inserted/removed.** An index key makes
React match the wrong DOM node to the wrong item across reorders, which shows
up as state (inputs, checkboxes, animations) sticking to the wrong row.

**Use `React.cache()` (or the framework's request memoization) to dedupe
repeated per-request work.** The same auth check or DB read called from
multiple components in one request tree should run once, not once per
call site — especially where the duplicate call is a DB round trip.

## Accessibility

**Interactive elements need a real element and a keyboard path.** A `<div>` or
`<span>` with an `onClick` is invisible to keyboard and screen-reader users —
use `<button>` for actions and `<a>`/`<Link>` for navigation, which get focus,
keyboard activation, and semantics for free. If a custom element must stay
interactive, it needs `role`, `tabIndex`, and an `onKeyDown` handler, not just
a mouse handler.

**Icon-only buttons and images need a text alternative.** An icon button with
no visible label needs `aria-label`; an `<img>` needs `alt` (or `alt=""` if
purely decorative). Without one, a screen reader announces nothing useful.

**Form controls need an associated label, not just a placeholder.** Every
`<input>`/`<select>`/`<textarea>` needs a `<label htmlFor>` or `aria-label` —
a placeholder disappears on input and isn't read as a label by assistive tech.

**Never remove the focus outline without a visible replacement.**
`outline: none` / `focus:outline-none` with nothing in its place makes the page
unusable by keyboard. Replace it with a visible `focus-visible` style, don't
just delete it.

**Virtualize large lists.** Rendering more than ~50 DOM nodes for a `.map()`
over an array is a real perf cliff on mid-tier devices — reach for
`content-visibility: auto` or a virtualization library instead of rendering
every row unconditionally.

**Honor `prefers-reduced-motion`.** An animation with no reduced-motion
fallback is a correctness gap for users who've asked the OS to turn motion
down, not a nice-to-have.

## Composition (non-blocking)

These are architectural opinions, not defects. Raise them as 💡 suggestions
only — never as a blocking or warning finding, and never insist on them over
a deliberate choice already in the surrounding code.

**Prefer composition over boolean-prop proliferation.** A component
accumulating flags like `isThread`, `isEditing`, `isCompact` to switch its own
behavior is heading toward exponential conditional logic. Splitting into
explicit variants or compound components (shared context, composed
subcomponents) usually reads better once there are three or more such props —
worth a suggestion, not a rewrite demand.

**React 19: `ref` is a normal prop.** `forwardRef` is unnecessary on new
components in a React 19 codebase — `ref` can be destructured like any other
prop. Only worth a note if the surrounding codebase has already moved off
`forwardRef` elsewhere; don't flag it in a React 18 project or an
otherwise-`forwardRef`-heavy file.

**Prefer `children` over `renderX` callback props** for simple composition —
render props still work and aren't a defect, just a suggestion where a
component takes a single `render`-style prop that could be `children` instead.

## Preferences

Do not mention these.

- Pass a function to `useState` for expensive initial values
  (`useState(() => expensive())`) rather than calling it inline; only worth
  raising if the computation is genuinely non-trivial.
- Don't wrap a simple expression with a primitive result in `useMemo` —
  comparing dependencies can cost more than the expression.
- Don't extract a component into `memo()` preemptively; do it when there's an
  actual re-render cost to avoid.

## Sources

Curated and paraphrased from:

- Vercel's `react-best-practices` agent skill (async/waterfalls, bundle size,
  server-side performance, re-render and rendering rules) — Rules section.
- Vercel's `composition-patterns` agent skill (boolean-prop proliferation,
  compound components, React 19 `ref`-as-prop, children over render props) —
  Composition section.
- [Vercel Web Interface Guidelines](https://github.com/vercel-labs/web-interface-guidelines)
  (accessibility, focus states, forms) — Accessibility section.

Not a transcription — trimmed to what's realistically catchable from a diff and
worth blocking or suggesting on; see each source for the full rule set and
rationale.
