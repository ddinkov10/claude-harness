#!/usr/bin/env bash
# Prepare this machine for claude-harness sync. Idempotent — re-run anytime,
# especially after `claude-sync update` (re-applies the Windows patch) or after
# adding a marketplace to claude-sync/settings.json.
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
SYNC_SCRIPT="$HOME/.local/share/claude-sync/claude-sync"
SYNC_BIN="$HOME/.local/bin/claude-sync"

command -v claude >/dev/null || { echo "error: claude CLI is required" >&2; exit 1; }

# --- 1. PATH shim for humans ----------------------------------------------
# Automation (the SessionStart hook) calls the repo script directly at
# ~/.local/share/claude-sync/claude-sync — nothing load-bearing lives in
# ~/.local/bin. This shim only lets you type `claude-sync` in a terminal.
# exec'ing the clone means it can never go stale (unlike a copy or a
# Windows "symlink"), and `claude-sync update` resolves its repo correctly
# because the real script path is what executes.
SHIM='#!/usr/bin/env bash
exec "$HOME/.local/share/claude-sync/claude-sync" "$@"'
if [[ ! -f "$SYNC_SCRIPT" ]]; then
    echo "warning: $SYNC_SCRIPT not found — install claude-sync first (see README)" >&2
fi
mkdir -p "$(dirname "$SYNC_BIN")"
if [[ ! -f "$SYNC_BIN" ]] || [[ "$(cat "$SYNC_BIN" 2>/dev/null)" != "$SHIM" ]]; then
    rm -f "$SYNC_BIN" # may be an old copy or symlink
    printf '%s\n' "$SHIM" >"$SYNC_BIN"
    chmod +x "$SYNC_BIN"
    echo "installed: $SYNC_BIN (exec shim)"
else
    echo "ok: $SYNC_BIN current"
fi

# --- 2. Marketplaces + plugins --------------------------------------------
# claude-sync only auto-installs plugins newly added by a sync merge and never
# retries failures, so this full-list pass is the recovery path.
"$SCRIPT_DIR/install-plugins.sh"

echo "Bootstrap complete."
