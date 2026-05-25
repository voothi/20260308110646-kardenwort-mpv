## Deferred Renderer Unification Candidates

This change intentionally unifies only the tooltip style surface. The broader DW/DM renderer merge remains out of scope for safety.

### Candidate 1: Shared Card/Text Event Builder For DW And DM Main Overlays
- Lift card/text ASS event formatting from `draw_dw` and `draw_drum` into common helpers.
- Keep layout and hit-zone logic separate at first.
- Goal: reduce style drift without changing navigation geometry.

### Candidate 2: Shared Border-Ownership Registry Per Overlay
- Replace mode-local border override calls with per-overlay ownership keys (`dw`, `search`, `tooltip`, `notice`, `seek`).
- Goal: prevent override depth leaks and hidden coupling between overlays.

### Candidate 3: Unified Style Context For All OSD Surfaces
- Create a normalized style context (`font`, `alpha`, `bord`, `shad`, `native-box policy`) for all surfaces.
- Goal: make `background-box` handling explicit and testable in one place.

### Candidate 4: Cross-Mode Snapshot Tests
- Add integration tests that compare generated ASS contracts for DW/DM/SRT across the same timeline snapshot.
- Goal: catch visual parity regressions before they reach manual screenshot review.
