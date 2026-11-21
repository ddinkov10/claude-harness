#!/usr/bin/env bash
# SessionStart hook for Claude Code on the web. The environment setup script
# clones this repo to /opt/claude-harness and runs this script once; the
# settings.json it writes runs it again at every session start, so config and
# plugins added to the repo after the environment snapshot was built still land.
# Output goes to the log only: hook stdout would enter the session context.
set -euo pipefail

HARNESS=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
SYNC="$HARNESS/claude-sync"
CLAUDE_DIR="$HOME/.claude"

mkdir -p "$CLAUDE_DIR"
exec >>"$CLAUDE_DIR/plugin-bootstrap.log" 2>&1
echo "=== web-session-start $(date -u +%FT%TZ) ==="

git -C "$HARNESS" pull -q

cat "$SYNC/CLAUDE.md" "$SYNC/professional-mode.md" "$SYNC/superdinq-mode.md" >"$CLAUDE_DIR/CLAUDE.md"
cp -rf "$SYNC/skills" "$CLAUDE_DIR/"
if [[ -d "$SYNC/agents" ]]; then cp -rf "$SYNC/agents" "$CLAUDE_DIR/"; fi

[[ -s "$HOME/.claude.json" ]] || echo '{}' >"$HOME/.claude.json"
jq --slurpfile s "$SYNC/mcp-servers.json" '.mcpServers = $s[0]' "$HOME/.claude.json" >"$HOME/.claude.json.tmp"
mv -f "$HOME/.claude.json.tmp" "$HOME/.claude.json"

# The synced hooks drive the local claude-sync loop and the mode banners; on the
# web this script is the sync, and the modes are appended to CLAUDE.md above.
# The celetis land allow lives in each product's untracked settings.local.json,
# which a cloud clone lacks.
# `claude plugin install` below rewrites enabledPlugins, so settings go first.
jq --arg hook "$HARNESS/web-session-start.sh" '
    del(.statusLine)
    | .hooks = {SessionStart: [{matcher: "", hooks: [{type: "command", command: $hook, timeout: 120}]}]}
    | .permissions.allow = ((.permissions.allow // []) + ["Bash(celetis --agent claude land *)"] | unique)
' "$SYNC/settings.json" >"$CLAUDE_DIR/settings.json"

"$HARNESS/install-plugins.sh"

# The celetis plugin runs the engine, so the engine takes the ref of the
# plugin's marketplace. Both stay at the snapshot until the snapshot is rebuilt.
install_bun() {
    local version=$1 dest tmp status
    dest=$(command -v bun || echo /usr/local/bin/bun)
    tmp=$(mktemp -d) &&
        curl -fsSL -o "$tmp/bun.zip" "https://github.com/oven-sh/bun/releases/download/bun-v$version/bun-linux-x64.zip" &&
        python3 -m zipfile -e "$tmp/bun.zip" "$tmp" &&
        install -m 755 "$tmp/bun-linux-x64/bun" "$dest"
    status=$?
    rm -rf "$tmp"
    return $status
}
install_celetis() {
    local ref floor tmp status
    ref=$(jq -r '.extraKnownMarketplaces.celetis.source.ref // "main"' "$SYNC/settings.json")
    tmp=$(mktemp -d "$HOME/.celetis-install.XXXXXX") &&
        git clone -q --branch "$ref" https://github.com/ddinkov10/celetis.git "$tmp/celetis" &&
        floor=$(sed -n "s/^export const bunFloor = '\(.*\)';/\1/p" "$tmp/celetis/engine/lib/config/core.ts") &&
        { bun -e "process.exit(Bun.semver.satisfies(Bun.version, '>=$floor') ? 0 : 1)" 2>/dev/null || install_bun "$floor"; } &&
        bun install --cwd="$tmp/celetis/engine" --frozen-lockfile --production --ignore-scripts &&
        BUN_RUNTIME_TRANSPILER_CACHE_PATH=0 DO_NOT_TRACK=1 bun --no-env-file --no-install --config=/dev/null --no-macros "$tmp/celetis/engine/celetis" install &&
        ln -sf "$HOME/.local/bin/celetis" /usr/local/bin/celetis
    status=$?
    rm -rf "$tmp"
    return $status
}
command -v celetis >/dev/null || install_celetis || echo "warning: could not install the celetis engine"

# A cloud session does not install the plugins that the repo's own settings
# enable. CLAUDE_PROJECT_DIR is set only when this runs as the hook.
PROJECT_SETTINGS="${CLAUDE_PROJECT_DIR:-}/.claude/settings.json"
if [[ -n "${CLAUDE_PROJECT_DIR:-}" && -f "$PROJECT_SETTINGS" ]]; then
    echo "== Project plugins: $PROJECT_SETTINGS =="
    # </dev/null: the CLI must not read the remaining names from the loop's pipe.
    jq -r '.extraKnownMarketplaces // {} | .[].source | .repo // .url // empty' "$PROJECT_SETTINGS" |
        while IFS= read -r m; do
            claude plugin marketplace add "$m" </dev/null || echo "warning: could not add marketplace $m"
        done
    jq -r '.enabledPlugins // {} | to_entries[] | select(.value == true) | .key' "$PROJECT_SETTINGS" |
        while IFS= read -r p; do
            claude plugin install "$p" --scope user </dev/null || echo "warning: could not install $p"
        done
fi
echo "=== done $(date -u +%FT%TZ) ==="
