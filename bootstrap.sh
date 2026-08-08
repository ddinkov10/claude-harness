#!/usr/bin/env bash
# Prepare this machine for claude-harness sync. Idempotent — re-run anytime,
# especially after `claude-sync update` (re-applies the Windows patch) or after
# adding a marketplace to claude-sync/settings.json.
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
SETTINGS="$SCRIPT_DIR/claude-sync/settings.json"
PLUGINS_LIST="$SCRIPT_DIR/claude-sync/plugins.list"
SYNC_SCRIPT="$HOME/.local/share/claude-sync/claude-sync"
SYNC_BIN="$HOME/.local/bin/claude-sync"

command -v jq >/dev/null || { echo "error: jq is required" >&2; exit 1; }
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

# --- 2. Register plugin marketplaces ------------------------------------
# extraKnownMarketplaces in settings.json is declarative only; the CLI needs
# `marketplace add` to actually fetch and cache each one before installs work.
echo "== Marketplaces =="
while IFS= read -r repo; do
    repo="${repo%$'\r'}" # native jq.exe emits CRLF on Windows
    [[ -z "$repo" ]] && continue
    if ! claude plugin marketplace add "$repo"; then
        echo "warning: could not add marketplace $repo (may already be registered)" >&2
    fi
done < <(jq -r '.extraKnownMarketplaces // {} | to_entries[] | .value.source.repo' "$SETTINGS")

# --- 3. Install plugins --------------------------------------------------
# claude-sync only auto-installs plugins newly added by a sync merge and never
# retries failures, so this full-list pass is the recovery path.
echo "== Plugins =="
while IFS= read -r plugin; do
    plugin="${plugin%$'\r'}" # tolerate CRLF checkouts
    [[ -z "$plugin" || "$plugin" == \#* ]] && continue
    if ! claude plugin install "$plugin" --scope user; then
        echo "warning: could not install $plugin (may already be installed)" >&2
    fi
done <"$PLUGINS_LIST"

echo "Bootstrap complete."
