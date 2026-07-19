# Baseline

Rules that apply across my projects, whatever they're written in.
Language-specific rules live in [`languages/`](languages/). Each repo's own
`CLAUDE.md` adds to both and wins where they disagree.

Two audiences: Claude writing code, and the PR reviewer
([REVIEW.md](REVIEW.md)) holding changes to it. So every rule here has to be
decidable from a diff. If a rule wouldn't justify blocking a PR, it belongs in
Preferences at the bottom, not in Rules.

## Rules

Reviewer: flag violations of these.

**Never silence a type error — fix the type.** Every language has an escape
hatch for asserting something the compiler can't prove: a cast, a force-unwrap,
a suppression comment. Reaching for one to make an error go away buries a bug
instead of fixing it. Legitimate uses exist at genuine external boundaries
(parsed input, third-party types); those should be obvious from context, and
worth a comment when they aren't.

**Never swallow an error.** Catching an error and discarding it — or only
logging it — is not error handling. Rethrow, return it, or report it. If the
catch really is intentional, say why in a comment. Empty catch blocks and
ignored error returns are findings every time.

**Never interpolate untrusted input into a query, command, or path.** Use
parameterised queries, argument arrays, and path-joining APIs. String
concatenation carrying a request value into SQL, a shell command, or a
filesystem path is a finding every time.

**Validate external input before use.** Anything crossing a trust boundary —
request bodies, query params, webhook payloads, file contents, IPC messages —
gets parsed and checked before it's used, not cast into the expected shape and
hoped for.

**Never commit secrets.** No API keys, tokens, credentials, or connection
strings in source, tests, or fixtures — including ones that look fake.

**Don't edit generated files by hand.** Anything produced by a build step,
codegen tool, or migration generator. Change the source and regenerate. Each
repo's `CLAUDE.md` names its own.

**Migrations are append-only.** Never edit or delete a migration that has been
applied to a deployed environment. Add a new one.

**Don't widen a public API to fix a caller.** If a function needs different
behaviour, add a parameter with a default or a new function — don't loosen a
type, relax a constraint, or make a required field optional so one call site
compiles.

**No shared mutable state across requests or invocations.** In any environment
where the process outlives a single unit of work — Workers isolates, long-lived
servers, background workers — module- or global-scope mutable state leaks
between users. Keep per-request state in the request scope.

**New public functions get a test.** Behaviour-preserving refactors don't need
new tests. Bug fixes do — one that fails without the fix.

## Preferences

Reviewer: **do not mention these at all** — not as a finding, not as a
non-blocking note, not to explain that you're not flagging them. Raising one
"but only as a preference" is still noise. They're for Claude writing code, not
grounds for blocking a PR.

- Prefer early returns to `else` branches.
- Don't extract a single-use helper preemptively — inline it unless it's reused
  or hides a genuinely complex boundary.
- Comments explain *why*, not *what*. Don't narrate the code.
- Match the file you're editing over any general convention.

## Commit and PR conventions

- Imperative mood, lowercase, no trailing period: `add preview deploy cleanup`.
- No listicles, no robot voice, no summarising the diff back at the reader.
- Say why the change exists. The diff already says what it does.
- Never use `--force` on a shared branch. `--force-with-lease` on your own.

## What the linter, formatter, and compiler own

Don't spend rules on these. Reviewer: report them only as part of the raw
command output, never as a finding:

unused imports and variables, formatting, import order, mutability keywords,
missing return types, unreachable code, exhaustiveness checks.
