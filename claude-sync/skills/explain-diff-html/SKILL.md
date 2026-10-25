---
name: explain-diff-html
description: Use when the user asks you to explain, walk through, or write up a code change — a diff, commit, branch, or PR — as a standalone interactive HTML page rather than a chat reply.
---

# Explain Diff

Produce one self-contained HTML page that teaches a code change to someone who has never seen it.

## The four sections

In this order, each an `<h2>` linked from a table of contents at the top.

**Background.** Explore the surrounding code broadly before writing. Two layers: deep background for beginners — say up front that a familiar reader can skip it — then narrow background covering only what this change touches.

**Intuition.** The essence, not the details. Toy data, concrete examples, diagrams.

**Code.** High-level walkthrough of the changes, grouped and ordered so each builds on the last.

**Quiz.** Five multiple-choice questions. Medium difficulty: answerable by someone who followed the substance, but not gotchas. Clicking an option reveals correct/incorrect plus per-option feedback.

## Output contract

- One HTML file. CSS and JS inline, no external requests.
- One long scrolling page with a table of contents. No tabs for top-level structure.
- Responsive enough to read on a phone.
- Saved outside the code repo, filename starting with today's date so files stay time-sorted and out of version control: `/tmp/YYYY-MM-DD-explanation-<slug>.html`

## Writing

Clarity and flow of Martin Kleppmann: classic style, engaging, with transitions that carry the reader between sections rather than four disconnected essays. Callouts for key concepts, definitions, and important edge cases.

## Diagrams

Pick a small number of diagram families and reuse them across cases. Two carry most explanations:

- A simplified sketch of the UI the user sees, for UI changes.
- A system diagram of data flow between components — always with example data flowing through it.

Never ASCII art. Diagrams are HTML and CSS; lists of things are HTML lists.

Every code block is a `<pre>`. A styled `<div>` instead needs `white-space: pre-wrap` in its CSS, or the browser collapses the block onto one line.

## Before you hand it over

Both steps. Source review is not verification — the quiz breaks in ways that only show up when the page runs.

**1. Structural check.**

```bash
python3 ~/.claude/skills/explain-diff-html/check.py <file>
```

Catches the defects that survive a source read: a duplicate `id` (a `<h2 id="quiz">` anchor and a `<div id="quiz">` mount make `getElementById` return the heading, so questions render inside the title and the container stays empty), a script looking up an id no element has (one null dereference at the top of an IIFE kills every feature below it), and a missing `<meta charset="utf-8">` (em dashes and arrows arrive as mojibake).

**2. Click the quiz.** Browser tooling generally blocks `file://`, so serve it:

```bash
python3 -m http.server 8731 --directory /tmp
```

Load `http://127.0.0.1:8731/<file>`, confirm five questions rendered, click an option, confirm the feedback and score appear. Then stop the server.
