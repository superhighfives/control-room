# Baseline

Rules that apply across my projects. Each repo's own `CLAUDE.md` adds to this
and wins where they disagree.

Two audiences: Claude writing code, and the PR reviewer
([REVIEW.md](REVIEW.md)) holding changes to it. So every rule here has to be
decidable from a diff. If a rule wouldn't justify blocking a PR, it belongs in
Preferences at the bottom, not in Rules.

## Rules

Reviewer: flag violations of these.

**Never use `as` to silence a type error.** Narrow with a type guard, or fix the
type. `as const` and `as unknown as T` at a genuine external boundary (parsed
JSON, third-party types) are fine — everything else is a suppressed bug.

**Never use `any` in `src/**`.** Use `unknown` and narrow. Tests may use `any`
in fixtures.

**Never swallow an error.** `catch (e) {}` and `catch (e) { console.error(e) }`
are not error handling. Rethrow, return a typed error, or report it — and if the
catch is genuinely intentional, say why in a comment.

**Never interpolate user input into SQL.** Use the query builder, or `sql` with
placeholders. A template literal carrying a request value into a query is a
finding every time.

**Validate request bodies before use.** Any handler reading `c.req.json()`,
`request.json()`, or form data parses it through a schema first. Do not cast the
result.

**Never commit secrets.** No API keys, tokens, or connection strings in source,
tests, or fixtures — including ones that look fake. Use env bindings.

**Don't edit generated files by hand.** `routeTree.gen.ts`, `worker-configuration.d.ts`,
`drizzle/**` migrations, and anything with a generated-file header. Change the
source and regenerate.

**Migrations are append-only.** Never edit or delete a migration that has been
applied to a deployed environment. Add a new one.

**No module-scope mutable state in Workers code.** Isolates are reused across
requests, so a module-level cache, counter, or accumulating array leaks data
between users. Put per-request state in the handler.

**Don't widen a public API to fix a caller.** If a function needs different
behaviour, add a parameter with a default or a new function — don't loosen a
type or make a required field optional so one call site compiles.

**New exported functions in `src/**` get a colocated test.** Behaviour-preserving
refactors don't need new tests. Bug fixes do — one that fails without the fix.

## Preferences

Reviewer: do not flag these. They're for Claude writing code, not grounds for
blocking a PR.

- Prefer early returns to `else` branches.
- Don't extract a single-use helper preemptively — inline it unless it's reused
  or hides a genuinely complex boundary.
- Prefer named exports.
- Comments explain *why*, not *what*. Don't narrate the code.
- Match the file you're editing over any general convention.

## Commit and PR conventions

- Imperative mood, lowercase, no trailing period: `add preview deploy cleanup`.
- No listicles, no robot voice, no summarising the diff back at the reader.
- Say why the change exists. The diff already says what it does.
- Never use `--force` on a shared branch. `--force-with-lease` on your own.

## What the linter and typechecker own

Don't spend rules on these, and reviewer: don't flag them. Biome and `tsc`
already catch them, and the review runs both:

unused imports and variables, formatting, import order, `const` vs `let`,
missing return types, unreachable code, exhaustive switch checks.
