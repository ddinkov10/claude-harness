---
name: spec-to-swarm
description: Use when the user asks for a prompt to hand back to Claude Code rather than for the work itself — "give me the prompt first", "write me a prompt to build X", "ultracode prompt", "fan out sub-agents prompt", "make this a /loop prompt" — or when they paste a maximalist Call-of-Duty-style prompt as a format template to copy.
---

# Spec to Swarm

## Overview

An ultracode prompt is a single self-contained message that turns one feature request into a fan-out, loop-until-perfect build. Its power comes from one move: **the quality bar is an external, named, blindly-comparable product**, not an adjective. "Make it good" is unfalsifiable. "A harsh critic compares it blind against the camera UI in Instagram and must say ours is at least as good" is a terminating condition.

Deliver the prompt. Do not execute it unless the user says to run it.

## When to Use

- User explicitly asks for the prompt text, not the implementation
- User pastes an example prompt and says "format like this"
- Task is big enough that a per-item sub-agent split is real work, not theater

**Not for:** a one-line fix, a rename, or anything where the honest answer is "this is 20 lines, just do it." Say that instead.

## The Output Contract

Emit one fenced code block containing these parts, in this order. Every part is required.

1. **Ambition line.** `I want you to <build X>` + the named external reference the result is measured against + "utterly perfect" + the specific quality dimensions that matter for this domain (textures/physics for a game; permission states/cleanup for a camera).
2. **Constraint line.** The stack, the platform API or library to use, what must NOT be added (new dependencies), and what existing code must be reused or matched. Name real files and directories from the repo.
3. **Exhaustive checklist.** Introduced with "Every one of these must be handled, none skipped:". 6–12 bullets of the actual edge cases, failure states, and platform quirks. This is the part that does the work — it is the fan-out unit.
4. **Fan-out directive.** Sub-agent per checklist item, `/loop` on each.
5. **The harsh critic.** A *separate* verifying sub-agent, described by what it concretely does — drives the real browser, denies the permission, resizes to mobile, screenshots each state — and what makes it send work back.
6. **Blind comparison exit.** "Don't stop until the verifying sub-agent compares this blind against `<named reference>` and says ours is at least as good."
7. **Verification commands.** The repo's real lint / build / test commands, plus what tests to add.
8. **Closing incantation.** `/loop until it's utterly perfect. Fan out sub-agents and ultracode.`

Then, **outside** the code block, 2–3 lines: what the work honestly is (rough LOC, the one file it lives in) and what the multi-agent loop actually buys. This is the calibration the user needs to decide whether to fire it.

## Calibration

| Input | Effect on the prompt |
|---|---|
| Broad greenfield build | Reference = a flagship product. 10–12 checklist bullets. |
| Feature inside an existing app | Reference = the best in-class version of that one flow. 6–9 bullets, all edge cases. |
| User names no reference | Pick the most obvious best-in-class one and name it explicitly. Never leave the bar as an adjective. |

## Harness Notes

`ultracode`, `/loop`, and sub-agent fan-out are real features, not flavor text — `ultracode` opts into multi-agent orchestration, `/loop` schedules repeats. Keep the words verbatim; changing them breaks the trigger.

## Common Mistakes

- **Vague checklist** ("handle errors gracefully"). Each bullet must name a state a critic can screenshot.
- **No named reference.** Without it there is no exit condition and the loop never terminates or terminates instantly.
- **Inventing file paths.** Read the repo enough to name real ones, or omit them.
- **Skipping the honest note.** The user asked for a maximalist prompt, not to be misled about the size of the job.
