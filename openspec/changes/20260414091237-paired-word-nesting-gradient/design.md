## Context

Presently, the Drum Window differentiates between two types of multi-word highlights for saved terms:
1. Contiguous (orange lines): These receive a gradient representation (e.g., changing background opacity) based on their nesting level within overlapping word sequences. This communicates the depth of overlapping bounds.
2. Non-contiguous/paired (purple lines): These are rendered properly with their split structure, but currently do not recalculate their visual representation to account for nesting within other highlights. Due to the increasing volume of overlapping paired and contiguous terms in a typical study session, it is critical to harmonize their visual treatment so paired terms also exhibit the appropriate gradient based on overlap.

## Goals / Non-Goals

**Goals:**
- Unify the alpha/gradient rendering logic so that both contiguous and split (paired) multi-word highlights utilize nesting awareness.
- Calculate nesting levels accurately for split terms depending on how many other terms overlap their boundaries.

**Non-Goals:**
- Changing the base color or style of highlights (paired words will remain purple, contiguous words remain orange).
- Modifying the underlying data extraction or saving logic.

## Decisions

- **Adapt Nesting Level Algorithm:** The current nesting logic loops through term bounds to establish depth. For paired words, which consist of multiple bounding boxes (`[start_a, end_a]`, `[start_b, end_b]`), the logic should be updated to account for overlapping boundaries across the whole span or per-chunk. Typically, nesting is calculated based on the overarching span of a term or exact bounding intersection. We will use the latter approach to increment the nesting depth factor on intersections.
- **Three-Level Discrete Color System:** Instead of a calculated alpha gradient, we will introduce three distinct color configuration options for split words: `anki_split_depth_1`, `anki_split_depth_2`, and `anki_split_depth_3`. This ensures the visual style is perfectly consistent with the existing `anki_highlight_depth_X` system used for orange highlights.

## Risks / Trade-offs

- **Performance Risk:** Calculating overlapping intersections for split bounding boxes could introduce slight overhead if a segment has an exorbitant amount of multi-word terms.
  *Mitigation:* The total number of saved terms visible on a single subtitle line is bounded and typically very small, ensuring O(N^2) complexity is negligible.
