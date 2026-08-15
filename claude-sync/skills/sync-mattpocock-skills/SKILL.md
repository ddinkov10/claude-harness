---
name: sync-mattpocock-skills
description: Sync the vendored Matt Pocock skills with upstream mattpocock/skills.
disable-model-invocation: true
---

# Sync Matt Pocock skills

25 skills in `~/.claude/skills/` are vendored copies of the `skills/engineering/` and `skills/productivity/` trees of `mattpocock/skills`. The plugin is **not** installed — these copies are the only versions, so nothing updates them automatically.

`upstream.sha` beside this file records the upstream commit the copies were last synced to. Diff upstream against **that commit**, never against the local files: the local files diverge on purpose, and a direct comparison reports every divergence as a change on every run.

## Steps

1. Read the baseline and the current upstream head:

   ```
   cat ~/.claude/skills/sync-mattpocock-skills/upstream.sha
   gh api repos/mattpocock/skills/commits/main --jq .sha
   ```

2. Equal? Report "in sync" and stop.

3. List the skill files that changed between them:

   ```
   gh api repos/mattpocock/skills/compare/<baseline>...<head> --jq '.files[] | .status + " " + .filename' | grep -E ' skills/(engineering|productivity)/'
   ```

   Ignore `skills/in-progress/` and `skills/misc/` — they are not vendored. Ignore every `agents/openai.yaml`.

4. Fetch each changed file at the new head:

   ```
   gh api "repos/mattpocock/skills/contents/<path>?ref=<head>" --jq .content | base64 -d
   ```

5. Port each change onto the local copy, applying the divergence rules below. A file that is new upstream is vendored whole; a file deleted upstream is deleted locally, reported by name.

6. Overwrite `upstream.sha` with the new head.

7. Report one line per skill: ported, added, deleted, or skipped-because-divergence.

Done when `upstream.sha` equals upstream head and every upstream delta is either ported or reported as covered by a divergence.

## Divergence rules — apply on every port and every newly added skill

| Rule | Detail |
|---|---|
| Drop the Codex directory | Never vendor `agents/` — it holds `openai.yaml`, which this harness does not read. Vendor every other file in the skill directory, including `references/`, `scripts/`, and sibling `*.md`. |
| Strip the invocation flag | Delete any `disable-model-invocation: true` line. Every vendored skill is model-invocable; this is the whole point of vendoring them. |
| Keep the local description | Never overwrite a local `description:` with upstream's. Local descriptions are rewritten into model-facing form — a trigger branch (`Use when …`) and a negative branch (`Not for …`) — because upstream writes human-facing one-liners for skills it expects you to type. If upstream changes a description's *meaning*, re-derive the local one from the new text in that same form. |
| Keep the renames | Two skills are vendored under different names to avoid shadowing. Rename the directory **and** the `name:` frontmatter field. |
| Vendor only the shipped trees | `skills/engineering/` and `skills/productivity/` only — these are what the plugin manifest shipped. |

### Renamed skills

| Upstream | Vendored as | Why |
|---|---|---|
| `code-review` | `matt-code-review` | `code-review` is a built-in Claude Code command. |
| `triage` | `matt-triage` | `triage` is a project-level command in some repos. |

### Skills whose descriptions are locally rewritten

`ask-matt`, `matt-code-review`, `grill-with-docs`, `implement`, `improve-codebase-architecture`, `setup-matt-pocock-skills`, `to-spec`, `to-tickets`, `matt-triage`, `wayfinder`, `grill-me`, `handoff`, `teach`, `to-questionnaire`, `wait-what`.

The other ten already ship model-facing descriptions and are vendored verbatim.

## Adding a skill that is new upstream

Before vendoring, check the name against existing skills and built-in commands. On a collision, vendor under a `matt-` prefix and add a row to the rename table above.
