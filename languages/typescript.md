# TypeScript

Applies to PRs touching `.ts` / `.tsx`. Sharpens [BASELINE.md](../BASELINE.md)
with the specific forms those rules take here.

## Rules

**Never use `as` to silence a type error.** Narrow with a type guard, or fix the
type. `as const` and `as unknown as T` at a genuine external boundary (parsed
JSON, third-party types) are fine — everything else is a suppressed bug.

**Never use `any` in source.** Use `unknown` and narrow. Tests may use `any` in
fixtures.

**No `@ts-ignore` or `@ts-expect-error` without a reason on the same line.**
A bare suppression is a bug with the alarm switched off.

**Empty or log-only catches are findings.** `catch (e) {}` and
`catch (e) { console.error(e) }` do not handle anything.

**Parse request bodies through a schema.** Any handler reading `c.req.json()`,
`request.json()`, or form data validates before use. Do not cast the result.

**Never build SQL with template literals carrying request values.** Use the
query builder, or `sql` with placeholders.

## Cloudflare Workers

**No module-scope mutable state.** Isolates are reused across requests, so a
module-level cache, counter, or accumulating array leaks data between users.

**`c.env.*` needs both a type and a binding.** A binding that type-checks
because someone widened the type, but isn't in `wrangler.jsonc`, fails at
runtime rather than at build. Secrets are the exception — they're typed but set
with `wrangler secret put`.

## Preferences

Do not mention these.

- Prefer named exports.
