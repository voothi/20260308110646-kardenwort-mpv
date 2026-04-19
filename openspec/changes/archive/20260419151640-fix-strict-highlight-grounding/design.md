## Context

The current highlighting engine uses a "fuzzy context check" as a fallback when strict coordinate-based grounding fails. This is intended to support legacy cards and provide resilience against slight subtitle shifts. However, for "New Generation" cards that include precise word-level indices, this fallback incorrectly matches identical terms in the same segment, leading to "highlight bleed."

## Goals / Non-Goals

**Goals:**
- Enforce strict index matching for local (non-global) highlights when metadata is available.
- Ensure all manual selections (including single clicks) generate grounding metadata.
- Prevent identical terms in the same subtitle from sharing a highlight.

**Non-Goals:**
- Removing the fuzzy check entirely (it's still needed for global mode and legacy cards).
- Changing the highlighting colors.

## Decisions

- **Gated Fuzzy Fallback**: In `calculate_highlight_stack`, the fuzzy check will be gated by a condition that checks if strict grounding was possible. If `data.__pivots` exists and we are not in global mode, failure of the strict check will prevent the fuzzy fallback from executing.
- **Single-Word Grounding**: The single-click export logic in the Drum Window will be updated to explicitly set `advanced_index`. This ensures that even single-word highlights are fully "grounded" and can be distinguished by the updated stack calculation.

## Risks / Trade-offs

- **Risk**: If a subtitle file is modified such that internal word indices change but the text remains identical, existing grounded highlights might stop rendering.
- **Trade-off**: This is acceptable as the priority is 100% precision for the user's current session and grounded exports.
