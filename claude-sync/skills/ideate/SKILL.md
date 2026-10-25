---
name: ideate
description: Explore new ideas for the current project through six lenses — code improvements, UI/UX, code quality, security, performance, documentation.
disable-model-invocation: true
---

Generate concrete, code-grounded improvement ideas for the current project. Adapted from Aperant's (AGPL-3.0) ideation agents. Each lens is a reference file in `prompts/`; load only the lenses you run.

| Lens | File | Finds |
|---|---|---|
| code-improvements | `prompts/code-improvements.md` | Features the existing code reveals as near-ready |
| ui-ux | `prompts/ui-ux.md` | Friction, inconsistency, and polish gaps in the live UI |
| code-quality | `prompts/code-quality.md` | Refactoring targets: smells, duplication, dead code |
| security | `prompts/security.md` | Exploitable weaknesses and hardening gaps |
| performance | `prompts/performance.md` | Measurable speed, size, and memory wins |
| documentation | `prompts/documentation.md` | Doc gaps ranked by onboarding impact |

## Process

1. **Context.** Read the project's `AGENTS.md`/`CLAUDE.md`. If the repo has a tracker (`docs/agents/issue-tracker.md`, or a `gh` remote), list open issues and any roadmap docs — an idea that duplicates planned work is dead on arrival.
2. **Lenses.** Arguments name lenses (any unambiguous prefix). With no arguments, ask which lenses to run (multi-select, all six offered).
3. **Explore.** For each chosen lens, read its prompt file and follow it. Ground every idea in evidence: an idea must cite files you actually read and patterns that actually exist; discard any idea whose evidence is thin.
4. **Deliver.** Present the ideas as cards, grouped by lens, strongest first. Offer to route accepted ideas onward: `/triage` where the project has it, otherwise file issues per the tracker doc.

## Idea card

Every idea, whatever the lens:

- **Title** — short and specific
- **Description** — what it does, or what is wrong
- **Rationale** — why the code reveals this; cite files
- **Effort** — trivial (<2h) | small (half day) | medium (1–3d) | large (3–7d) | complex (1–2w)
- **Affected files** — real paths
- **Approach** — how to implement it with existing code

plus the lens-specific fields its prompt file names. 3–7 ideas per lens, mixed effort levels; a short honest list beats a padded one.
