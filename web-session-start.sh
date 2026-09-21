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
# `claude plugin install` below rewrites enabledPlugins, so settings go first.
jq --arg hook "$HARNESS/web-session-start.sh" '
    del(.statusLine)
    | .hooks = {SessionStart: [{matcher: "", hooks: [{type: "command", command: $hook, timeout: 120}]}]}
' "$SYNC/settings.json" >"$CLAUDE_DIR/settings.json"

"$HARNESS/install-plugins.sh"
echo "=== done $(date -u +%FT%TZ) ==="
