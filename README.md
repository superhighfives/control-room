# claude-code-reviews

One review standard, shared across my repos.

[`REVIEW.md`](REVIEW.md) is the actual standard. [`.github/workflows/review.yml`](.github/workflows/review.yml)
is a reusable workflow that runs it against a pull request.

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
    uses: superhighfives/claude-code-reviews/.github/workflows/review.yml@main
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
    uses: superhighfives/claude-code-reviews/.github/workflows/review.yml@main
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
| `node_version` | `22` | Used for the install step. |
| `standards_ref` | `main` | Pin to a tag or SHA if you want a repo to hold still. |
| `timeout_minutes` | `20` | |

## Per-repo standards

`REVIEW.md` is the baseline. Repo-specific rules belong in that repo's
`CLAUDE.md` — the reviewer reads the root file plus any in directories the PR
touched, and holds the change to them.

That split is deliberate: this repo says how to review, `CLAUDE.md` says how
that codebase wants to be written.
