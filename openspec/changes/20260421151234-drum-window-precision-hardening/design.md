## Context

The Drum Window rendering was previously word-index based, which caused issues with split selections (Purple) and punctuation inheritance. Users reported "Brick bleed" where punctuation incorrectly appeared as an intersection and "white holes" in multi-line selections.

## Goals / Non-Goals

**Goals:**
- Implement "Footprint Shadows" using absolute subtitle timelines for accurate nesting and intersection detection.
- Enable high-precision punctuation coloring that independently verifies record membership.
- Standardize "Pixel-Perfect Export" using fractional indexing to eliminate greedy trailing punctuation.
- Ensure selection continuity in multi-line drags.

**Non-Goals:**
- Adding character-level positions to the Anki TSV `WordSourceIndices` field.
- Changing keyboard navigation behavior (remains word-based).

## Decisions

- **Absolute Shadow Timeline**: Records are grounding using `time_total = sub_idx * 1000 + logical_idx`. This allows the system to detect nesting even in the gaps of split selections.
- **L_EPSILON Standardization**: Defined `L_EPSILON = 0.0001` for all floating-point logical index comparisons.
- **Private Punctuation Stacks**: The rendering Pass 2 is refactored to perform a per-token stack recalculation. Punctuation only turns Brick if it is physically part of both an Orange and a Purple term.
- **Infinity Boundaries for Middle Lines**: During export, for lines 1 to N-1, the selection boundary is logic-gated to capture the entire tail of the line. Precise fractional boundaries are only applied to the terminal word of the drag.

## Risks / Trade-offs

- **Performance**: Shadow checks are O(N_highlights) per token. Mitigated by pre-calculating footprints (`__min_l`, `__max_l`) during the Anki load phase.
- **Data Integrity**: By relying on the `WordSource` text for punctuation highlights, we avoid breaking established Anki field conventions.
