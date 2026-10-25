# Code Improvements lens

You are hunting **code-revealed** opportunities: features and improvements that emerge from patterns already in the codebase — extended, applied elsewhere, or scaled up. What the CODE says is possible, not what users might want; product strategy is out of scope.

## Where to look

- **Pattern extensions** (trivial→medium): CRUD for one entity → a similar entity; a filter/sort/export/validation that exists for one case → more cases.
- **Architecture opportunities** (medium→complex): the data model, API structure, component architecture, or state pattern already supports X with minimal change.
- **Configuration** (trivial→small): hard-coded values that fit an existing settings pattern.
- **Utility additions** (trivial→medium): validators, formatters, helpers that could cover adjacent cases.
- **UI enhancements** (trivial→medium): loading/empty/error states and shortcuts that follow patterns already present elsewhere.
- **Data handling** (small→large): pagination, search, auto-save where the pattern exists for a sibling view.
- **Infrastructure extensions** (medium→complex): under-used plugin points, event systems, caching, logging.

For each candidate, open the pattern file, see how it is used, and confirm the extension path before it becomes an idea.

## Extra card fields

- **Builds upon** — the existing feature/pattern it extends
- **Existing patterns** — the concrete pattern to follow, by file

## Rules

1. A pattern that does not exist in the codebase disqualifies the idea — that is a roadmap item, not a code improvement.
2. Aim for a mix: 1–2 trivial/small, 2–3 medium, 1–2 large/complex.
3. The approach must reference the real code that enables it.

**Good**: "Add search to user list" (search exists in product list); "Add CSV export" (JSON export exists); "Add webhook support" (event system and HTTP handlers exist).
**Bad**: "Add real-time collaboration" (no WebSocket infra); "Add AI suggestions" (no ML integration); "Add feature X because users want it" (not code-revealed).
