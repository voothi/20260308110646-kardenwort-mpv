## Context

The codebase was rolled back to commit `131f530` (`20260429210156`) after a series of 27 commits on branch `20260429211359` broke Drum Mode C. The root cause was an overly-invasive restructuring of the rendering pipeline: `calculate_highlight_stack` was modified to inject semantic coloring inline, `draw_drum` was restructured to use a new token-stream architecture, and FSM state transitions were altered — all in a single delivery. This cascading change broke hit-zone geometry, FSM activation, and click-to-word mapping.

The stable codebase at the rollback point has all prior v1.54.x features working: Yellow/Pink selection, Orange/Purple/Brick highlighting, multi-line wrapping, Book Mode, keyboard navigation, configurable keybindings, tooltip rendering, and search.

Two open change projects remain un-implemented and un-archived:
- `20260429185737-rework-string-preparation-for-export` — unified export engine
- `20260429195210-unify-subtitle-export-and-keyboard-granularity` — keyboard token selection + export parity

Additionally, the failed branch produced three new spec domains (`global-semantic-coloring`, `keyboard-selection-granularity`, `performance-hardening`) and refinements to existing specs that should be preserved.

## Goals / Non-Goals

**Goals:**
- Transfer all valuable specification artifacts from the failed branch into the openspec catalog.
- Implement the unified export engine (`prepare_export_text`) from the two open change projects.
- Implement keyboard token-level granularity (Shift+Arrow navigation).
- Implement semantic punctuation coloring as a non-destructive post-processing pass.
- Implement performance caching without visual changes.
- Maintain zero regression on Drum Mode C, Window W, FSM, hit-zones, and all existing highlighting.

**Non-Goals:**
- Restructuring `draw_drum` or `draw_dw` rendering loop architecture.
- Modifying `calculate_highlight_stack` internal logic.
- Altering FSM state machine transitions or activation logic.
- Changing the tokenizer or index storage format.
- Implementing the full "global token stream" architecture that failed.

## Decisions

### Decision 1: Phased Delivery with Hard Isolation Boundaries

**Choice**: Deliver in 5 strictly ordered phases (A→E), each independently verifiable.

**Rationale**: The failed branch delivered rendering changes, FSM changes, export changes, and spec changes simultaneously. A single defect cascaded through all systems. Phased delivery ensures that Phase B (export engine) cannot introduce rendering regressions, and Phase D (semantic coloring) is constrained to a post-processing pass.

**Alternative Considered**: Single-pass implementation — rejected because it was the exact approach that caused the regression.

### Decision 2: Semantic Coloring as Post-Processing Pass

**Choice**: Implement punctuation color propagation as a **read-only scan** over the finalized `color_array` produced by the existing `calculate_highlight_stack`, rather than modifying the stack calculation itself.

**Rationale**: The failed branch modified `calculate_highlight_stack` to integrate semantic coloring, which broke the fragile balance between Orange depth counting, Purple depth counting, and Brick intersection logic. A post-processing pass cannot break these calculations because it only reads the final color assignments and fills in uncolored punctuation tokens.

**Implementation**: After `calculate_highlight_stack` produces `{word_idx → color}`, a new function `apply_semantic_punctuation_colors(color_array, token_list)` scans for uncolored punctuation tokens adjacent to colored words and propagates the neighboring color. This function is called in `draw_drum` and `draw_dw` AFTER the highlight stack is computed but BEFORE the ASS string is assembled.

**Alternative Considered**: Inline integration into `calculate_highlight_stack` — rejected because this is exactly what broke in the failed branch.

### Decision 3: Export Engine as Pure Data Function

**Choice**: `prepare_export_text` is a pure function that takes selection data and returns a string. It has no side effects on rendering state, OSD, or FSM.

**Rationale**: This ensures Phase B code changes cannot interact with the rendering pipeline in any way. The function consumes token lists from `build_word_list_internal` and outputs strings — completely decoupled from visual code.

### Decision 4: Performance Caching with Transparent Invalidation

**Choice**: Implement `FSM.ANKI_WORD_MAP` as a denormalized lookup table rebuilt on TSV reload events. Implement `DRUM_DRAW_CACHE` / `DRUM_LAYOUT_CACHE` with hash-based invalidation (subtitle index + highlight fingerprint).

**Rationale**: The rendering output MUST be byte-identical with and without caching. Caching is purely a performance optimization. Invalidation triggers on: TSV reload, subtitle index change, selection change, highlight toggle.

### Decision 5: Subsume Open Changes

**Choice**: The two open change projects (`20260429185737`, `20260429195210`) are subsumed by this proposal. Their artifacts are incorporated into the spec files of this change. They will be archived as "superseded" after this change is applied.

**Rationale**: These changes were never applied to the codebase and their scope overlaps with Phases B and C of this proposal. Merging them avoids duplicate work and ensures a single authoritative implementation plan.

## Risks / Trade-offs

### Risk: Semantic Coloring Doesn't Cover All Edge Cases as a Post-Pass
The post-processing approach might miss complex multi-pass coloring scenarios (e.g., bracketed phrases spanning subtitle boundaries where the bracket token is in a different subtitle entry).
- **Mitigation**: The post-pass scans across the entire visible token sequence (all subtitle entries in the rendering window), not just within individual lines. Edge cases from the failed branch's test scenarios will be regression-tested against the post-pass implementation.

### Risk: Export Engine Changes Alter TSV File Format
Changing how text is cleaned and exported could produce different TSV entries for the same selection.
- **Mitigation**: The change is intentional — preserving punctuation the user selected is the goal. Existing TSV files remain valid. Only NEW exports will reflect the improved fidelity.

### Risk: Shift+Arrow Navigation Interferes with Existing Keybindings
Adding token-level movement could conflict with existing Shift+Arrow selection logic.
- **Mitigation**: The change is additive — standard Arrow moves between words (unchanged), Shift+Arrow adds token-level precision. This is the same pattern already established for Ctrl+Arrow (jump 5 words) and Ctrl+Shift+Arrow (jump 5 lines).

### Trade-off: Performance Caching Adds Memory Overhead
Maintaining word maps and draw caches increases memory usage proportional to subtitle count and highlight density.
- **Mitigation**: For a typical 1-hour video with ~800 subtitles and ~200 highlights, the overhead is negligible (<1MB). Cache is cleared on video file change.
