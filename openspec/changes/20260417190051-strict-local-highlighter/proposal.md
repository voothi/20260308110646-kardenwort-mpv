## Why

The current "Local Mode" for Anki word highlighting (when Global Highlight is OFF) is too permissive, leading to visual "bleed" and duplicate highlights. Currently, a 10-second temporal window and a 15-subtitle scan range are used, which often causes words saved from nearby sentences or different scenes to appear in the current subtitle view. This is especially problematic for common words (like "die") or when the user has a large `SentenceSource` context.

## What Changes

We will implement stricter filtering for the highlighter when `anki_global_highlight` is `false`. Specifically:
- Reducing the default local fuzzy window for single words.
- Restricting the subtitle scan range for multi-word terms in local mode.
- Adding a configuration option to allow users to tune the strictness of the local window.

## Capabilities

### New Capabilities
None.

### Modified Capabilities
- `anki-highlighting`: Restrict the visual re-rendering scope in local mode to prevent temporal bleed.
- `high-recall-highlighting`: Tighten the adaptive temporal window and inter-segment scan range for non-global highlighting.

## Impact

The changes will primarily affect `scripts/lls_core.lua` within the `calculate_highlight_stack` function. Highlighting precision will increase in local mode, ensuring that only terms relevant to the current subtitle's immediate context are displayed.
