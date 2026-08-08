# superspec — local vendoring notes

Vendored from https://github.com/WangX0111/superspec (pinned — see `PINNED_SHA.txt`).

## What was excluded from upstream
`scripts/` (shell/python test harness), `.github/`, `examples/`, `extension.yml`,
`README*`, `.git`. Only the runtime skill content is shipped: `SKILL.md`, `commands/`,
`references/`, `templates/`, `assets/`, `LICENSE`.

## Local patches (re-apply after any update)
This harness runs superspec inside Claude Code, where obra/superpowers is a **plugin**,
not a `~/.agents/skills/` install. Two edits make superspec detect and use those plugin
skills instead of dropping to its built-in fallbacks:

1. `SKILL.md` — Prerequisites: added a "Claude Code harness" note listing the six
   superpowers skills as already loaded / invokable via the Skill tool.
2. `references/superpowers-bridge.md` — Detection Logic: added precedence step 0 that
   treats a `superpowers:{skill-name}` Skill-tool invocation as "available".

## Update ritual (stay current, review first)
```powershell
git clone https://github.com/WangX0111/superspec.git "$env:TEMP\ss-new"
git -C "$env:TEMP\ss-new" diff (Get-Content "$env:USERPROFILE\.claude\skills\superspec\PINNED_SHA.txt") HEAD -- SKILL.md commands references templates
# review the delta. If clean: re-run the selective copy, bump PINNED_SHA.txt, re-apply the 2 patches above.
```
