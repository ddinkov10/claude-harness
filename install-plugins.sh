#!/usr/bin/env bash
# Register every marketplace declared in claude-sync/settings.json, then install
# every plugin in claude-sync/plugins.list and disable each one settings.json
# sets to false. Idempotent: the CLI commands are no-ops when already done. A
# failure is only a warning so that one unreachable marketplace (a private repo
# without credentials) never blocks the others.
set -uo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
SETTINGS="$SCRIPT_DIR/claude-sync/settings.json"
PLUGINS_LIST="$SCRIPT_DIR/claude-sync/plugins.list"

command -v jq >/dev/null || { echo "error: jq is required" >&2; exit 1; }
command -v claude >/dev/null || { echo "error: claude CLI is required" >&2; exit 1; }

# extraKnownMarketplaces in settings.json is declarative only; the CLI needs
# `marketplace add` to actually fetch and cache each one before installs work.
echo "== Marketplaces =="
while IFS= read -r repo; do
    repo="${repo%$'\r'}" # native jq.exe emits CRLF on Windows
    [[ -z "$repo" ]] && continue
    if ! claude plugin marketplace add "$repo"; then
        echo "warning: could not add marketplace $repo" >&2
    fi
done < <(jq -r '.extraKnownMarketplaces // {} | to_entries[] | .value.source.repo' "$SETTINGS")

echo "== Plugins =="
while IFS= read -r plugin; do
    plugin="${plugin%$'\r'}" # tolerate CRLF checkouts
    [[ -z "$plugin" || "$plugin" == \#* ]] && continue
    if ! claude plugin install "$plugin" --scope user; then
        echo "warning: could not install $plugin" >&2
        continue
    fi
    # `plugin install` enables the plugin, so restore the off switch.
    if jq -e --arg p "$plugin" '.enabledPlugins[$p] == false' "$SETTINGS" >/dev/null; then
        claude plugin disable "$plugin" --scope user || echo "warning: could not disable $plugin" >&2
    fi
done <"$PLUGINS_LIST"
