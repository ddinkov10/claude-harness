# UI/UX lens

See the app as users see it. Launch the running app and drive it with browser tools (Playwright MCP, or the project's `run` skill); read components statically only when no browser is available, and say so in the output.

## What to inspect

- **Landing + navigation**: hierarchy, active states, consistency.
- **Interactive elements**: hover, focus, loading, error, and success states on buttons and forms.
- **Forms**: labels, placeholders, validation messages, submit placement.
- **Empty states**: message, call to action, visual appeal.
- **Mobile**: resize to 375×812 — navigation, touch targets (≥44px), reflow, text size.
- **Accessibility**: images without alt, buttons without text, inputs without labels, contrast, keyboard navigation, focus indicators, `lang`/`title`.

## Extra card fields

- **Category** — usability | accessibility | performance-perception | visual | interaction
- **Current state → Proposed change** — what is there now, the specific change (component + CSS/markup level)
- **User benefit**

## Rules

1. Report what you actually observed in the running app; take screenshots where they carry the point.
2. Be specific: "add hover state to the primary button in Header.tsx", never "improve buttons".
3. Propose fixes that match the existing design system and tokens.
4. Rank by user impact.
