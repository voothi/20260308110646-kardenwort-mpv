# Proposal: Finalize Drum Window Highlighting Stabilization

## Problem Statement
Following the hybridization of the highlighting engine to restore index-based tokenization (Lute v3), several visual and behavioral regressions remain. While multi-line selection is functional, the system does not yet fully adhere to the "Ground Truth" specification regarding highlight priorities and semantic punctuation coloring. Specifically:
- **Selection Overlap**: Persistent selections (Ctrl+LMB) do not always override database highlights with the correct Pale Yellow priority.
- **Punctuation Isolation**: Trailing punctuation in multi-word phrases is often excluded from highlighting, breaking visual continuity.
- **Intersection Logic**: High-order intersections (3+ overlaps) need to be strictly mapped to the "Brick Color" palette levels.
- **Global Match Bleed**: Common functional words (e.g., "die", "the") require hardened neighborhood verification to prevent spurious highlights in Global Mode.

## Proposed Solution
We will perform a comprehensive pass over the lls_core.lua rendering engine to ensure 100% compliance with the window-highlighting-spec.

### Key Enhancements
1.  **Priority Correction**: Refactor the draw_dw and draw_drum rendering loops to strictly enforce:
    - Persistent Multi-Selection (Beige/Pale Yellow) -> Highest Priority.
    - Database Highlights (Orange/Purple/Brick) -> Secondary.
    - Active Focus/Hover (Vibrant Yellow) -> Tertiary (only if not persistently selected).
2.  **Phrase-Aware Punctuation**: Update the rendering engine to color internal and trailing punctuation tokens when they are bounded by constituent words of a matched phrase.
3.  **Harden Multi-Segment Bridging**: Refine the index-based lookup to ensure that phrases spanning segment boundaries (within 1.5s) are consistently rendered without "flicker" during scrolling.
4.  **Brick Color Intersection**: Finalize the $L = \text{clamp}(O + S - 1, 1, 3)$ logic for mixed-palette overlaps.

## Expected Outcomes
- Elimination of "highlight bleed" for common words via strict neighbor verification.
- Perfect visual alignment with the "Tri-Palette" intensity system.
- Robust, deterministic visual state restoration when deselecting paired terms.
