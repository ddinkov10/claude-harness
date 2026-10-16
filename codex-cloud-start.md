Before task work, refresh the shared harness:

```bash
git -C "$HOME/.local/share/claude-harness" pull --ff-only
```

Run the startup script for each project checkout used by this task. Pass its absolute checkout path:

```bash
bash "$HOME/.local/share/claude-harness/codex-cloud-setup.sh" start /absolute/project/checkout
```

Read `AGENTS.md` from the active `CODEX_HOME`, or from `~/.codex` when `CODEX_HOME` is unset. These are the user's shared engineering and communication instructions.

Inspect this cloud task's own skill and tool catalogs. Confirm that the Celetis, Superpowers, and personal skills are available. A separate CLI catalog does not prove that the cloud task loaded them. Report missing skills as setup failures before lane work.

Use cloud tools that the current task exposes. The setup also configures Context7 and headless Playwright for the installed CLI. A CLI MCP configuration does not prove that either server is available as a native cloud tool. Before work that needs an absent tool, report that setup gap. Do not claim that desktop-only tools are available.

Before Celetis child work, read the installed plugin's `docs/hosts/codex.md`. Check its dispatch requirements against the cloud task's actual tools and supported model/effort pairs. Do not start a nested Codex model session to bypass a missing cloud tool or child control.
