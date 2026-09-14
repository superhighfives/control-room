#!/usr/bin/env bash
# Provisions a repo to use control-room's review workflow with real APPROVE
# capability. The GitHub App itself is installed on "all repositories" for
# this account, so new repos are covered automatically — the one thing that
# doesn't propagate automatically is the secret, since personal GitHub
# accounts have no org-wide secrets. This just does that one remaining step.
set -euo pipefail

if [ $# -ne 1 ]; then
  echo "Usage: $(basename "$0") <repo>   (bare name defaults to superhighfives/<repo>)" >&2
  exit 1
fi

REPO="$1"
[[ "$REPO" == */* ]] || REPO="superhighfives/$REPO"

KEY_PATH="${CONTROL_ROOM_APP_KEY:-$HOME/.config/control-room/app-private-key.pem}"

if [ ! -f "$KEY_PATH" ]; then
  echo "error: App private key not found at $KEY_PATH" >&2
  echo "  (set CONTROL_ROOM_APP_KEY to point elsewhere, or place the control-room-review App's .pem there)" >&2
  exit 1
fi

if ! gh repo view "$REPO" >/dev/null 2>&1; then
  echo "error: can't see $REPO — check the name and that you're authenticated (gh auth status)" >&2
  exit 1
fi

echo "Setting APP_PRIVATE_KEY on $REPO..."
gh secret set APP_PRIVATE_KEY --repo "$REPO" < "$KEY_PATH"

if ! gh secret list --repo "$REPO" | cut -f1 | grep -qx "CLAUDE_CODE_OAUTH_TOKEN"; then
  echo "warning: $REPO has no CLAUDE_CODE_OAUTH_TOKEN secret — the review workflow needs that too." >&2
fi

if ! gh api "repos/$REPO/contents/.github/workflows/claude-code-review.yml" >/dev/null 2>&1; then
  echo "note: $REPO has no .github/workflows/claude-code-review.yml yet — copy the template from control-room's README (Usage section)." >&2
fi

echo "Done."
