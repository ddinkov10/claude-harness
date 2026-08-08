---
name: bulgarian-localization
description: Use when writing, translating, or reviewing Bulgarian-language text — a Bulgarian bank for a quiz-builder quiz, UI strings, or any generated Bulgarian content — before delivering it as final. Triggers include "на български", "Bulgarian version", "преведи", bilingual quiz banks, and any Bulgarian output that must meet native standard (правопис, граматика, пунктуация, естественост).
---

# Bulgarian Localization

## Overview

Make generated Bulgarian read like a native editor wrote it. Companion to the quiz-builder skill, which is vendored per-project in the quizzes repo at `.claude/skills/quiz-builder/` (no longer installed globally) — but this skill applies to ANY generated Bulgarian text, quiz or not.

Distilled from a real project: a first-pass Bulgarian translation that was structurally perfect with decent voice still contained **11 certain errors and ~30 English calques**. Every one was caught only by a dedicated native-level proofread pass. Skipping that pass is how the errors shipped the first time.

**Corrected exemplar** (tone, terminology, typography): `~/Dinq/TEMPLE/Principles_Quiz/index.html`, the `const QUIZZES_BG` bank. READ-ONLY reference.

## Process

1. **Translate meaning, never structure.** Sentence-by-sentence word-order transfer from English is the root cause of most defects. Read the sentence, drop the English, write the Bulgarian sentence a native would say.
2. **ALWAYS run a dedicated proofread pass after drafting.** Dispatch a fresh-context subagent prompted as a native Bulgarian editor. Give it the extracted plain Bulgarian text (never the surrounding code) plus [proofread-checklist.md](proofread-checklist.md). Findings must come back as: **location + exact current phrase + rule violated + exact fix + confidence** (`CERTAIN` rule violation vs `SUGGESTION` naturalness). This step is not optional — see Red Flags.
3. **Vet findings before applying.** Reviewers can suggest fixes that break other constraints. For quiz options specifically: every fix must preserve quiz-builder's length rule (correct option ≤25% longer than the longest distractor). If the suggested fix breaks it, find a shorter equivalent — don't skip the fix and don't break the rule.
4. **When paired with quiz-builder:** the Bulgarian bank mirrors the source bank structurally — same question count, types, correct-answer indices, scenario presence. Re-run `node verify.js index.html` (parity + length-cue checks) after ANY language fix.

## Register

Pick one form of address — ти or вие — and keep it absolutely consistent across every string. Localize UI details too: option letters А/Б/В/Г, keyboard hints, labels (the exemplar uses „Ситуация“ for scenario blocks, not „Сценарий“).

## Verification (must run before delivering)

Programmatic, on the extracted Bulgarian text (not code — JS string delimiters are legitimately `"`):

```bash
# Pronoun ѝ must be U+045D. A standalone й is ALWAYS the wrong spelling of it:
grep -nE '(^|[^[:alnum:]])й([^[:alnum:]]|$)' bg.txt
python3 -c "print(open('bg.txt',encoding='utf-8').read().count('ѝ'), 'x U+045D')"

# Bulgarian quotes are „…“ (U+201E/U+201C). Straight or English quotes are wrong:
grep -n '["”]' bg.txt
```

If paired with a source-language bank: structural parity via quiz-builder's `verify.js`.

Then the human-grade check: the fresh-eyes proofread pass from Process step 2. Both are required; the programmatic scans catch typography, only the proofread catches calques and grammar.

## Red Flags — do the proofread pass anyway

| Rationalization | Reality |
|---|---|
| "The translation looks clean" | The real project's first pass looked clean too. It had 11 errors and ~30 calques. |
| "I translated it carefully myself" | The drafting context cannot see its own calques. Fresh context is the point. |
| "It's a small amount of text" | The „че/дали“ error reverses meaning in one word. Size doesn't protect you. |
| "The programmatic checks passed" | They only cover typography and parity. Grammar and calques need the editor pass. |
| "No time for a second pass" | One subagent pass is cheaper than shipping a translation that asserts the opposite of the source. |
