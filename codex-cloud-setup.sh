#!/usr/bin/env bash
set -euo pipefail

HARNESS=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
MODE=${1:-install}
CODEX_DIR=${CODEX_HOME:-"$HOME/.codex"}
TOOLS="$HOME/.local/share/codex-cloud-tools"

case "$MODE" in
    install|start) ;;
    *) echo 'usage: codex-cloud-setup.sh install|start [project checkout]' >&2; exit 2 ;;
esac

if [[ "$MODE" == install ]]; then
    [[ "$(uname -s)" == Linux ]] || { echo 'codex-cloud: install requires Linux' >&2; exit 1; }
    missing=0
    for tool in git gh jq perl node npm python3 curl; do
        command -v "$tool" >/dev/null || missing=1
    done
    if [[ "$missing" == 1 ]]; then
        if [[ "$(id -u)" == 0 ]]; then
            apt-get update
            apt-get install -y --no-upgrade git gh jq perl nodejs npm python3 curl ca-certificates
        else
            sudo -n apt-get update
            sudo -n apt-get install -y --no-upgrade git gh jq perl nodejs npm python3 curl ca-certificates
        fi
    fi
    node -e 'if (Number(process.versions.node.split(".")[0]) < 18) process.exit(1)' || {
        echo 'codex-cloud: Node.js 18 or later is required' >&2; exit 1;
    }
    if ! command -v codex >/dev/null; then
        if [[ "$(id -u)" == 0 ]]; then
            npm install -g @openai/codex@0.162.1
        else
            sudo -n "$(command -v node)" "$(command -v npm)" install -g @openai/codex@0.162.1
        fi
    fi
    if ! command -v uv >/dev/null; then
        mkdir -p "$TOOLS"
        curl -LsSf https://astral.sh/uv/0.10.0/install.sh -o "$TOOLS/uv-install.sh"
        if [[ "$(id -u)" == 0 ]]; then
            env UV_INSTALL_DIR=/usr/local/bin UV_NO_MODIFY_PATH=1 sh "$TOOLS/uv-install.sh"
        else
            sudo -n env UV_INSTALL_DIR=/usr/local/bin UV_NO_MODIFY_PATH=1 sh "$TOOLS/uv-install.sh"
        fi
    fi
    npm install --prefix "$TOOLS" --no-audit --no-fund @playwright/mcp@0.0.83
    "$TOOLS/node_modules/.bin/playwright" install --with-deps chromium
fi

for tool in git gh jq perl node npm python3 codex uv; do
    command -v "$tool" >/dev/null || { echo "codex-cloud: $tool is required; run install first" >&2; exit 1; }
done
codex plugin add --help >/dev/null
PROJECT=$(git -C "${2:-$PWD}" rev-parse --show-toplevel)
[[ -x "$TOOLS/node_modules/.bin/playwright-mcp" ]] || {
    echo 'codex-cloud: Playwright MCP is missing; run install first' >&2; exit 1;
}

if [[ -n "${GH_TOKEN:-${GITHUB_TOKEN:-}}" ]]; then gh auth setup-git; fi

codex plugin marketplace add ddinkov10/celetis --ref main
codex plugin marketplace upgrade celetis
celetis_install=$(codex plugin add celetis@celetis --json)
celetis_root=$(printf '%s\n' "$celetis_install" | jq -er '
    select(.pluginId == "celetis@celetis") | .installedPath | strings | select(length > 0)
') || { echo 'codex-cloud: invalid Celetis installation metadata' >&2; exit 1; }

codex plugin marketplace add obra/superpowers --ref v7.0.0
codex plugin marketplace upgrade superpowers-dev
superpowers_install=$(codex plugin add superpowers@superpowers-dev --json)
superpowers_root=$(printf '%s\n' "$superpowers_install" | jq -er '
    select(.pluginId == "superpowers@superpowers-dev") | .installedPath | strings | select(length > 0)
') || { echo 'codex-cloud: invalid Superpowers installation metadata' >&2; exit 1; }

[[ "$celetis_root" == /* && "$superpowers_root" == /* &&
    -d "$celetis_root/skills" && -d "$superpowers_root/skills" ]] || {
    echo 'codex-cloud: an installed plugin has no skills directory' >&2; exit 1;
}

mkdir -p "$CODEX_DIR" "$PROJECT/.agents/skills"
exclude=$(git -C "$PROJECT" rev-parse --git-path info/exclude)
case "$exclude" in /*) ;; *) exclude="$PROJECT/$exclude" ;; esac
mkdir -p "$(dirname "$exclude")"
touch "$exclude"

link_skills() {
    local name=$1 source=$2 relative destination
    relative=".agents/skills/$name"
    destination="$PROJECT/$relative"
    if git -C "$PROJECT" ls-files --error-unmatch "$relative" >/dev/null 2>&1 ||
        { [[ -e "$destination" ]] && [[ ! -L "$destination" ]]; }; then
        echo "codex-cloud: refusing to replace $destination" >&2
        exit 1
    fi
    [[ -d "$source" ]] || { echo "codex-cloud: missing $source" >&2; exit 1; }
    ln -sfn "$source" "$destination"
    if ! grep -Fxq "/$relative" "$exclude"; then printf '/%s\n' "$relative" >>"$exclude"; fi
}

link_skills claude-harness "$HARNESS/claude-sync/skills"
link_skills codex-harness "$HARNESS/codex-sync/skills"
link_skills celetis "$celetis_root"
link_skills superpowers "$superpowers_root"

cat "$HARNESS/claude-sync/CLAUDE.md" \
    "$HARNESS/claude-sync/professional-mode.md" \
    "$HARNESS/claude-sync/superdinq-mode.md" >"$CODEX_DIR/AGENTS.md"

codex mcp add context7 --url https://mcp.context7.com/mcp
codex mcp add playwright -- "$TOOLS/node_modules/.bin/playwright-mcp" --headless --isolated --browser chromium

printf 'codex-cloud: ready for %s\n' "$PROJECT"
printf '%s\n' 'codex-cloud: check the active cloud skill catalog and MCP tools before lane work'
