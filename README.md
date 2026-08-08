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
EOF

# 5. Bootstrap: register plugin marketplaces + install plugins (idempotent — re-run anytime)
~/claude-harness/bootstrap.sh

# 6. First sync (pulls harness config, including the SessionStart auto-sync hook)
PATH="/opt/homebrew/bin:$PATH" claude-sync sync
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
EOF

# Bootstrap FIRST on Windows: patches claude-sync for MSYS md5sum (see caveats),
# registers marketplaces, installs plugins
~/claude-harness/bootstrap.sh

claude-sync sync
```

Windows caveats:

- The synced SessionStart hook runs the repo script `$HOME/.local/share/claude-sync/claude-sync sync` directly through bash (nothing load-bearing depends on `~/.local/bin`). Claude Code on Windows uses Git Bash for hooks when available — make sure Git Bash is installed **before** starting Claude Code, or the hook fails (harmless, but no auto-sync).
- The `PATH="/opt/homebrew/bin:$PATH"` prefix in the hook command is a macOS-ism; on Windows/Linux the directory doesn't exist and the prefix is a no-op.
- No symlinks needed: `bootstrap.sh` installs `~/.local/bin/claude-sync` as a tiny exec shim (works without Developer Mode, never goes stale, and `claude-sync update` works from PATH). It exists purely for typing `claude-sync` in a terminal.
- Upstream claude-sync has two silent Windows bugs, both fixed in our private fork: (1) MSYS `md5sum` emits a binary marker (`hash *./file`) that breaks checksum parsing — sync reports "Everything in sync" while transferring **nothing**; (2) native `jq.exe` emits CRLF line endings — the trailing `\r` empties the enabledPlugins intersection, so `plugins.list` gets regenerated wrong (drops installed plugins) and syncs that upstream. `claude-sync update` pulls from the fork, so the fixes survive updates.

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
