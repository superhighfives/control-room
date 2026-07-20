# control-room

One review standard and one set of baseline rules, shared across my repos.

- [`REVIEW.md`](REVIEW.md) — *how* to review. Sections, what to raise, what to
  leave alone.
- [`BASELINE.md`](BASELINE.md) — *what* the code has to hold to. Hard rules,
  plus an explicit do-not-flag list.
- [`.github/workflows/review.yml`](.github/workflows/review.yml) — reusable
  workflow that runs both against a pull request.

Each repo's own `CLAUDE.md` adds to `BASELINE.md` and wins where they disagree.
Nothing needs syncing — the workflow checks this repo out at review time.

## Why this exists

The default setup on most of my repos ran the `code-review` plugin, which is
tuned for precision: it scores each finding 0-100 for confidence and discards
everything below 80, and its false-positive list explicitly excludes
pre-existing issues, likely-intentional changes, test coverage, and general
code quality.

The effect was reviews that said "No issues found" while a plain `@claude
review please` on the same PR produced three genuinely useful observations —
every one of which the plugin was designed to filter out.

So this drops the plugin and uses the bare action with an explicit prompt. The
prompt is the product. The YAML is incidental.

## Usage

Add `.github/workflows/claude-code-review.yml` to a repo:

```yaml
name: Claude Code Review

on:
  pull_request:
    types: [opened, synchronize, ready_for_review, reopened]

permissions:
  contents: read
  pull-requests: write
  issues: write
  id-token: write
  actions: read

jobs:
  review:
    uses: superhighfives/control-room/.github/workflows/review.yml@main
    secrets:
      CLAUDE_CODE_OAUTH_TOKEN: ${{ secrets.CLAUDE_CODE_OAUTH_TOKEN }}
```

That works with no dependency install — the reviewer reads the code and says so.

**The `permissions` block is required, not optional.** A called workflow can
only narrow the caller's permissions, never widen them. If your repo's default
workflow token is read-only (Settings → Actions → Workflow permissions), leaving
it out fails the run at startup with `startup_failure` and no job, no log, and
no annotation explaining why.

To let it actually run your typechecker and linter rather than reasoning about
them from source, pass the commands:

```yaml
permissions:
  contents: read
  pull-requests: write
  issues: write
  id-token: write
  actions: read

jobs:
  review:
    uses: superhighfives/control-room/.github/workflows/review.yml@main
    with:
      setup_command: pnpm install --frozen-lockfile
      verify_commands: |
        pnpm typecheck
        pnpm lint
    secrets:
      CLAUDE_CODE_OAUTH_TOKEN: ${{ secrets.CLAUDE_CODE_OAUTH_TOKEN }}
```

### Inputs

| Input | Default | Notes |
| --- | --- | --- |
| `setup_command` | `''` | Dependency install. Empty skips it, and the reviewer is told not to claim it ran checks. |
| `verify_commands` | `''` | One command per line. Only meaningful with `setup_command`. |
| `runtime` | `node` | `node`, `bun`, or `none` when the toolchain is already on the runner. |
| `runs_on` | `ubuntu-latest` | Runner label. `macos-latest` for anything needing Xcode. |
| `node_version` | `22` | Only when `runtime` is `node`. |
| `standards_ref` | `main` | Pin to a tag or SHA if you want a repo to hold still. |
| `timeout_minutes` | `20` | |

## Languages

[`BASELINE.md`](BASELINE.md) is language-agnostic — it states each rule in terms
of the thing that goes wrong, not the syntax that causes it. Files in
[`languages/`](languages/) sharpen those into the specific forms a rule takes:
`as` and `any` in [TypeScript](languages/typescript.md), `!` and `try!` in
[Swift](languages/swift.md).

The reviewer reads the baseline, then only the language files a PR actually
touches. A language with no file still gets reviewed — against the baseline and
the conventions visible in the surrounding code — it just doesn't get the
sharpened version. Adding a language is one new file; nothing else changes.

## Reviews land

The review runs again on every push, and each run is stateless — it reads the
whole diff fresh. To keep that from meaning "hunt for a new nit forever," each
round first reads its own earlier reviews on the PR (every review starts with a
`<!-- control-room:review -->` marker so they're findable) and calibrates:

- **Blocking** is re-derived every round, so a new push that introduces a new
  blocking bug still gets caught.
- **Non-blocking** shrinks instead of refreshing. An observation you already
  made and pushed past is one you've chosen to accept, so it isn't raised again
  — and the reviewer doesn't manufacture a replacement.

When blocking is clear and the author has already iterated, the review leads
with a verdict — ready to merge, production-ready even if not perfect — and
stops. A cleared PR converges to "done" in a couple of rounds instead of
generating fresh nits indefinitely.

## PRs that change the workflow can't be reviewed

`claude-code-action` validates that the calling workflow file is byte-identical
to the copy on the default branch. Any PR that edits `.github/workflows/`
fails that check, and the action **skips and exits 0** — green tick, no comment,
about one second of runtime.

That silence is the same failure this repo exists to fix: a review that says
nothing looks exactly like a review that found nothing. So the workflow checks
whether a review was actually posted and, if not, comments explaining why. It
posts once per PR, not once per push.

Nothing can make those PRs reviewable — the validation happens before Claude
runs. Merging is what fixes it.

## Adding a rule

`BASELINE.md` is meant to grow. Two tests before a rule goes in:

1. **Would removing it cause a mistake?** If Biome or `tsc` already catches it,
   or Claude already gets it right, it's noise — and a bloated file dilutes the
   rules that matter.
2. **Would you want a bot to block a PR over it?** If not, it goes in
   Preferences, not Rules. Unqualified rules produce false positives, and false
   positives are how you learn to ignore the reviewer.

Phrase rules so a violation is visible in the diff: name the token, state the
scope, put the exception in the same sentence. "Never use `as` to silence a type
error; narrow with a type guard" is checkable. "Handle errors properly" is not.

Repo-specific rules go in that repo's own `CLAUDE.md`, not here.
