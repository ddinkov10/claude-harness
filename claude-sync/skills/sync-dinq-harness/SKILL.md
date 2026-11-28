---
name: sync-dinq-harness
description: Merge upstream obra/superpowers into the dinq-harness plugin repo, re-apply the fork's divergences, bump the version, push, and update the installed plugin. Use when the user asks to sync, update, or pull upstream into dinq-harness.
disable-model-invocation: true
---

Repo: `~/Dinq/dinq-harness`. Remotes: `upstream` = obra/superpowers, `origin` = ddinkov10/dinq-harness. Baseline is recorded by git; do not keep a separate sha file.

## Steps

1. `cd ~/Dinq/dinq-harness && git status --porcelain` must be empty. Stop and report if it is not.
2. `git fetch upstream`. If `git merge-base --is-ancestor upstream/main main`, report "in sync with upstream at $(git rev-parse --short upstream/main)" and stop.
3. Show `git log --oneline main..upstream/main`. Then `git merge --no-edit upstream/main`.
4. On conflicts: for every conflicted file run `git checkout --theirs <file>`, then re-apply the divergence table below, then `git add` and `git commit --no-edit`.
5. `grep -rl 'superpowers:' skills hooks | xargs sed -i '' 's/superpowers:/dinq-harness:/g'`. Then `grep -rn 'superpowers:' skills hooks` must print nothing.
6. Read the upstream version: `git show upstream/main:.claude-plugin/plugin.json | jq -r .version`. Set `version` to `<that>-dinq.1` in both `.claude-plugin/plugin.json` and `.claude-plugin/marketplace.json` (`plugins[0].version`).
7. `claude plugin validate .` and `claude plugin validate .claude-plugin/plugin.json`. `git ls-files -s skills hooks scripts | grep -c 100755` must be 13 or explained by an upstream change.
8. `git add -A && git commit -m "Sync upstream <short sha>, version <version>"`, `git push`, then `claude plugin update dinq-harness@dinq`.
9. Report: upstream commits merged, conflicts resolved, new version, and tell the user to restart Claude Code.

## Divergence table (re-apply after every merge)

| File | Ours |
|---|---|
| `.claude-plugin/plugin.json` | `name: dinq-harness`, `version: <upstream>-dinq.N`, `homepage` and `repository`: `https://github.com/ddinkov10/dinq-harness` |
| `.claude-plugin/marketplace.json` | `name: dinq`, `owner: {name: Dinq, email: ddinkov10@gmail.com}`, `plugins[0].name: dinq-harness`, `plugins[0].version`, `plugins[0].source: "./"` |
| `hooks/session-start` line 27 | `'dinq-harness:using-superpowers'` |
| `skills/**` | `superpowers:` → `dinq-harness:` |
| `DINQ.md` | ours only; keep |

Everything else takes upstream.

## Local edit without an upstream sync

Bump only `N` in both manifests (`6.3.0-dinq.1` → `6.3.0-dinq.2`), commit, push, `claude plugin update dinq-harness@dinq`. The version string is compared literally; without a bump the installed copy does not change.
