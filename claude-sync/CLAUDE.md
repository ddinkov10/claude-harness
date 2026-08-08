# Engineering Principles

- Do not preserve backward compatibility. Remove obsolete paths instead of adding compatibility layers, fallbacks, or migrations.
- Choose the simplest implementation that fully meets the current requirements. Avoid speculative abstractions, configuration, and indirection.
- Grow the system in layers. Start from the smallest version that works end to end, and add each new capability on top of a product that already works. Never trade a working product for unfinished complexity.
- Keep components modular and concerns clearly separated.
- Prefer established, well-maintained libraries when they reduce overall complexity or improve reliability. Do not reimplement common functionality without a clear reason.
- Lean on the dependencies already in the project before writing your own implementation or adding packages. Do not assume a library lacks a capability without checking its documentation and types.
- Make architectural decisions for the long term. Do not accept a stopgap that only works for now and is meant to be replaced later.
- Study how established products solve the problem before designing a solution. Adopt their proven patterns and conventions rather than inventing an approach from scratch.
- Default to no comments. Ship the code alone. A comment is allowed only when the information is impossible to recover from the code and losing it would cost a reader real time: a non-obvious constraint or invariant, or why this approach was chosen over a viable alternative. This is the rare exception, not a habit — assume almost every block, function and file needs none. Never paraphrase the code below it.
- Match the comment density and documentation style of the surrounding code, treating it as a ceiling rather than a quota. A heavily commented file is not permission to add more.
- Delete comments that restate the code, narrate steps, or record what changed. Apply this to the code you touch, not only to the code you add.
