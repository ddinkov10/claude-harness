---
name: sync-upstream-skills
description: Sync professional-mode.md and superdinq-mode.md with their upstream repos (caveman, ponytail).
disable-model-invocation: true
---

# Sync upstream skills

Two local skills are near-1:1 derivations of upstream repos. The `upstream/` folder beside this file holds each upstream file as of the last sync — diff against the snapshot, never against the local file, because the local file diverges on purpose.

| Upstream (GitHub) | Snapshot | Local derived file |
|---|---|---|
| `JuliusBrussee/caveman` — `skills/caveman/SKILL.md` | `upstream/caveman.md` | `~/.claude/professional-mode.md` |
| `dietrichgebert/ponytail` — `skills/ponytail/SKILL.md` | `upstream/ponytail.md` | `~/.claude/superdinq-mode.md` |

## Steps

1. Fetch both upstream files:

   ```
   gh api repos/JuliusBrussee/caveman/contents/skills/caveman/SKILL.md --jq .content | base64 -d
   gh api repos/dietrichgebert/ponytail/contents/skills/ponytail/SKILL.md --jq .content | base64 -d
   ```

2. Diff each fetched file against its snapshot. Both identical: report "in sync" and stop.

3. For each changed file, port the upstream delta onto the local derived file, keeping every intentional divergence listed below, then overwrite the snapshot with the fetched content.

4. Report per file: "in sync", or each ported change in one line plus any upstream change skipped because a divergence covers it.

Done when both snapshots equal current upstream and every upstream delta is either ported to the local file or reported as covered by an intentional divergence.

## Intentional divergences — keep on every port

Both files:

- Frontmatter `name`/`description` renamed (`professional` / `superdinq`); mode name renamed throughout the body, including deactivation phrases ("stop professional" / "stop superdinq").
- `PROFESSIONAL MODE ACTIVE` / `SUPERDINQ MODE ACTIVE` line added at top of body.
- Intensity levels removed: no level table, no default/switch lines, no per-level examples. Only the **full** level's behavior is kept, as a `## Behavior` section with full-level examples.

`professional-mode.md`:

- Caveman's self-reference exception ("user explicitly ask what the mode is") dropped.
- `(/caveman-compress exempt)` clause dropped from Boundaries.

`superdinq-mode.md`:

- `ponytail:` corner-cut comment marker renamed to `superdinq:`.
- "(pair with Caveman for terse prose)" dropped from Boundaries.
- `argument-hint` and `license` frontmatter dropped.
