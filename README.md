# claude-harness

Claude Code harness synced across machines via claude-sync (git mode) — installed from our **private fork** [ddinkov10/claude-sync](https://github.com/ddinkov10/claude-sync) of [baptisterajaut/claude-sync](https://github.com/baptisterajaut/claude-sync), which carries Windows/MSYS fixes upstream lacks. Synced content lives in [`claude-sync/`](claude-sync/): `CLAUDE.md`, `settings.json`, `skills/`, `statusline/`, `plugins.list`.

## New machine setup

### macOS

```bash
# 1. Prerequisites: git, jq, bash >= 4 (macOS ships 3.2)
brew install bash jq gh uv   # uv: used by pdf-inspector skill
gh auth login   # if not already authenticated

# 2. Install claude-sync (private fork — gh auth required)
gh repo clone ddinkov10/claude-sync ~/.local/share/claude-sync
# bootstrap.sh (step 5) puts a `claude-sync` shim on PATH; ensure
# ~/.local/bin is in PATH (add to ~/.zshrc if missing):
#   export PATH="$HOME/.local/bin:$PATH"

# 3. Clone this repo
git clone https://github.com/ddinkov10/claude-harness.git ~/claude-harness

# 4. Configure claude-sync (git mode)
mkdir -p ~/.config/claude-sync
cat > ~/.config/claude-sync/config <<'EOF'
BACKEND="git"
GIT_REPO="$HOME/claude-harness"
GIT_SUBDIR="claude-sync"
CLAUDE_DIR="$HOME/.claude"
EOF
cat > ~/.config/claude-sync/synclist <<'EOF'
CLAUDE.md
settings.json
skills/
agents/
plugins.list
statusline/
professional-mode.md
superdinq-mode.md
EOF

# 5. Bootstrap: first sync (pulls harness config, including the SessionStart
# auto-sync hook), then register plugin marketplaces + install plugins
# (idempotent — re-run anytime)
~/claude-harness/bootstrap.sh
```

### Windows

claude-sync is a bash script — run everything below inside **Git Bash** (ships bash 4.4+; installed with [Git for Windows](https://gitforwindows.org)). Also install [jq](https://jqlang.github.io/jq/) and [gh](https://cli.github.com).

```bash
# In Git Bash:
gh auth login   # if not already authenticated (private fork)
gh repo clone ddinkov10/claude-sync ~/.local/share/claude-sync

git clone https://github.com/ddinkov10/claude-harness.git ~/claude-harness

mkdir -p ~/.config/claude-sync
cat > ~/.config/claude-sync/config <<'EOF'
BACKEND="git"
GIT_REPO="$HOME/claude-harness"
GIT_SUBDIR="claude-sync"
CLAUDE_DIR="$HOME/.claude"
EOF
cat > ~/.config/claude-sync/synclist <<'EOF'
CLAUDE.md
settings.json
skills/
agents/
plugins.list
statusline/
professional-mode.md
superdinq-mode.md
EOF

# Bootstrap: first sync, then register plugin marketplaces + install plugins
# (idempotent — re-run anytime)
~/claude-harness/bootstrap.sh
```

Windows caveats:

- The synced SessionStart hook runs the repo script `$HOME/.local/share/claude-sync/claude-sync sync` directly through bash (nothing load-bearing depends on `~/.local/bin`). Claude Code on Windows uses Git Bash for hooks when available — make sure Git Bash is installed **before** starting Claude Code, or the hook fails (harmless, but no auto-sync).
- The `PATH="/opt/homebrew/bin:$PATH"` prefix in the hook command is a macOS-ism; on Windows/Linux the directory doesn't exist and the prefix is a no-op.
- No symlinks needed: `bootstrap.sh` installs `~/.local/bin/claude-sync` as a tiny exec shim (works without Developer Mode, never goes stale, and `claude-sync update` works from PATH). It exists purely for typing `claude-sync` in a terminal.
- Upstream claude-sync has two silent Windows bugs, both fixed in our private fork: (1) MSYS `md5sum` emits a binary marker (`hash *./file`) that breaks checksum parsing — sync reports "Everything in sync" while transferring **nothing**; (2) native `jq.exe` emits CRLF line endings — the trailing `\r` empties the enabledPlugins intersection, so `plugins.list` gets regenerated wrong (drops installed plugins) and syncs that upstream. `claude-sync update` pulls from the fork, so the fixes survive updates.

## Claude Code on the web

Web sessions run in a fresh container, so there is no claude-sync install there. The environment's setup script (Environment settings on claude.ai) is only these two lines:

```bash
git clone https://github.com/ddinkov10/claude-harness.git /opt/claude-harness
/opt/claude-harness/web-session-start.sh
```

`web-session-start.sh` pulls the repo, writes `~/.claude/CLAUDE.md` (with both mode files appended), `skills/`, `agents/`, and a `settings.json` whose only hook runs the script itself again at every session start. It then runs `install-plugins.sh`, so a marketplace or plugin added to the repo after the environment snapshot was built is still installed. At each session start it also installs the plugins (and their marketplaces) that the session's own repo enables in its `.claude/settings.json`, because a cloud session does not install them; a project needs no cloud hook of its own. It logs to `~/.claude/plugin-bootstrap.log` and prints nothing.

The environment snapshot rebuilds on its own when the setup script or allowed network hosts change, and about every 7 days; until then, the hook adds new skills but never removes deleted ones. A private marketplace (`dinq`) needs a git credential in the container; without one its add fails with a warning and the rest still install.

## Codex Cloud

`codex-cloud-setup.sh` prepares a reusable Linux environment. It reuses the shared instructions and personal skills in `claude-sync/`. `codex-sync/skills/` adds the personal Codex skills that the Claude sync does not hold. The professional and superdinq modes load through `AGENTS.md` from the existing mode files, so each mode has one source.

The installer adds Celetis from `main` and Superpowers from `v7.0.0`, the version used by the local Codex harness. It installs Playwright MCP 0.0.83 with Chromium. It installs Codex CLI 0.162.1 when no CLI exists. It installs uv 0.10.0, the local version, when absent, so `pdf-inspector` can run. The environment needs Node.js 18 or later. Missing system tools are installed with `apt-get`; a non-root setup needs passwordless `sudo`. Codex and uv installations also use `sudo` when needed.

At startup, the script refreshes both Git marketplaces and installs their current packages. It reads the returned `installedPath` values. It exposes the complete plugin packages through ignored links under the project's `.agents/skills/`, so their relative references still resolve. The personal skill links use the shared source directories. Deleted source skills do not leave stale copies. The script refuses to replace a tracked path or a normal file or directory at a link destination.

The script writes `AGENTS.md` in the active `CODEX_HOME`, or `~/.codex` when unset, from the shared instructions and both mode files. It configures Context7 and headless, isolated Playwright through `codex mcp add`. Other CLI configuration stays in place. Run it only in the dedicated cloud environment; it manages that environment's global `AGENTS.md` and those two MCP entries.

### Environment settings

1. Open **Settings > Codex Cloud > Environments > Create environment**. Select the project repository. Each environment needs this setup; it is not an account-wide default for every possible repository.
2. Enable internet access during setup and tasks. Use the package-manager preset. Add the GitHub hosts used by Git and `gh`: `github.com`, `api.github.com`, `raw.githubusercontent.com`, `codeload.github.com`, `objects.githubusercontent.com`, and `release-assets.githubusercontent.com`. Also allow `astral.sh`, `cdn.playwright.dev`, `playwright.download.prss.microsoft.com`, and `mcp.context7.com`. Keep the domains required by the project's own dependencies.
3. Give `git` read access to private `ddinkov10/celetis`. Give `gh` the project access that its lanes need, including issues and pull requests. If the environment's existing GitHub identity does not supply this, add `GH_TOKEN` as a personal environment variable through **Personal vault** and request that key in the environment. The task can read a direct environment variable. Do not put a token in the repository or the setup text. When a token is present, the script uses `gh auth setup-git`; it does not store the token in a source file.
4. Use this **Install script**. Its working directory must be a project checkout. For multiple project checkouts, run the installer for each one with its absolute path.

   ```bash
   set -euo pipefail
   cloud_harness="$HOME/.local/share/claude-harness"
   if [ -d "$cloud_harness/.git" ]; then
       git -C "$cloud_harness" pull --ff-only
   else
       git clone https://github.com/ddinkov10/claude-harness.git "$cloud_harness"
   fi
   bash "$cloud_harness/codex-cloud-setup.sh" install "$PWD"
   ```

5. Use the contents of [`codex-cloud-start.md`](codex-cloud-start.md) as the **Start skill**. It refreshes the harness before each task and runs the lighter `start` mode for each project checkout. The `start` mode does not reinstall browser packages or system tools. It needs the same GitHub access as installation.
6. Publish the environment. Start a new task from it. Republish after changing installation dependencies. Existing tasks retain their own files and setup.

The official [cloud environment documentation](https://learn.chatgpt.com/docs/environments/cloud-environments) describes these settings and the supported lifecycle. Personal local skills do not sync to cloud automatically. Repository skills are supported. The [skill documentation](https://learn.chatgpt.com/docs/build-skills) describes `.agents/skills` discovery and symlink support.

### What the setup can prove

The tests check fresh setup, repeat startup, configuration preservation, and failed private-plugin installation. They use an isolated home and real Codex CLI configuration commands. The Linux check also installs the real Playwright package and opens an isolated test page. The private plugin boundary is mocked in CI; CI receives no private repository credential.

```bash
python3 -m unittest discover -s tests -p '*_test.py' -v
```

The live checks of Git marketplace installation and skill discovery use an isolated `CODEX_HOME`. They start no Codex model turn. A successful CLI check does not prove native cloud activation. After publishing, check the cloud task's own skill catalog and tool catalog. Confirm the child controls required by the installed Celetis host reference before lane work. Celetis still requires the project's launcher and workflow wiring.

Enable supported account plugins through the cloud Plugins directory. The local account also enables `documents`, `pdf`, `spreadsheets`, `presentations`, `template-creator`, `visualize`, and `code-review`; enable their cloud versions where the platform offers them. A desktop plugin cache is not a portable cloud installation. Installing a CLI MCP entry does not add a tool to a running hosted task; use that task's supported connection controls and confirm its actual tools. Context7's remote URL is `https://mcp.context7.com/mcp`. The installed Playwright server is available to CLI clients and shell tests; native cloud access remains a separate platform check.

The setup does not install the desktop app's `node_repl` binary, its browser/computer integrations, Orca, herdr, or the local agent board. The platform supplies its own supported native tools. Orca and orchestration skill text remains available, but their local runtime is not provided. The cloud environment documentation currently lists computer and browser use as unsupported. No local credentials, session history, plugin cache, or desktop hooks are copied.

## Daily use

Sync runs automatically at every Claude Code session start (SessionStart hook in the synced `settings.json`). Manual commands:

```bash
claude-sync status    # per-file sync state
claude-sync sync      # bidirectional sync
claude-sync diff      # local vs remote
claude-sync fix       # Claude-assisted conflict resolution
claude-sync resolve <files>  # accept local version
```

Known issue: `--dry-run` is unreliable (observed pushing anyway) — don't rely on it.

Re-run `~/claude-harness/bootstrap.sh` (idempotent) after adding a new marketplace to `claude-sync/settings.json` (registers it on this machine).

## Maintaining the claude-sync fork

`claude-sync update` pulls our private fork (Windows fixes included). To pull in upstream improvements (one-time `remote add` per machine, then merge and push):

```bash
git -C ~/.local/share/claude-sync remote add upstream https://github.com/baptisterajaut/claude-sync.git
```

```bash
git -C ~/.local/share/claude-sync fetch upstream && git -C ~/.local/share/claude-sync merge upstream/main && git -C ~/.local/share/claude-sync push origin main
```

## What is NOT synced

Machine-local by design: credentials, `history.jsonl`, `sessions/`, `transcripts/`, `cache/`, `projects/`, plugin cache, `settings.local.json`, `CLAUDE.local.md`.
