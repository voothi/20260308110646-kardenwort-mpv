## Why

While the recent "Adaptive Continuity" update fixed visual highlighting, the primary Anki export engine (Middle Click) was still capturing "raw" text including boundary punctuation (e.g., `Umbruch.`, `ehrlich,`). Additionally, overlapping highlights (Word + Phrase) could cause flickering or incorrect punctuation coloring if not properly aggregated.

## What Changes

- **Sanitized Anki Export**: The `MBTN_MID` export button and `cmd_dw_export_anki` logic will now proactively strip leading and trailing punctuation/whitespace from captured terms.
- **Overlapping Highlight Aggregation**: Hardened the `has_phrase` detection in `calculate_highlight_stack` to ensure that if a word is part of ANY phrase on screen, its punctuation remains colored (Visual Flow) even if it's also a single-word study item.
- **Unified Capture Logic**: Synchronized the "Clean Capture" logic between the Clipboard (`Ctrl+C`) and Anki Export (`MBTN_MID`) handlers.

## Capabilities

### New Capabilities
- None.

### Modified Capabilities
- `high-recall-highlighting`: Hardens the requirement for **Adaptive Punctuation Rendering** to handle multi-match scenarios and **Clean Boundary Capture** for the Anki database.

## Impact

- **Affected Code**: `scripts/lls_core.lua` (specifically `calculate_highlight_stack` and `cmd_dw_export_anki`).
- **Dependencies**: None.
- **User Experience**: Cleaner Anki cards and more stable, "flow-oriented" highlighting for complex text.
