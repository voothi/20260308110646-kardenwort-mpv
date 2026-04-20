# Proposal: Correcting Pivot-Point Anchoring

## Goal
The goal of this change is to resolve a critical non-compliance in the **`drum-window-indexing`** specification. We will replace the current geometric-center-based pivot calculation with a precise character-offset anchoring system to eliminate "context drift" during Anki exports, specifically for identical terms appearing in the same subtitle segment.

## Reasoning
The current implementation in `lls_core.lua` (within `dw_anki_export_selection` and `ctrl_commit_set`) calculates `pivot_pos` by simply taking the midpoint of the subtitle line (`#cleaned / 2`). This violates the specification which requires the pivot to be the midpoint of the *specific word* focused by the user.

When multiple instances of the same word (e.g., "die" or "41 bis 45") exist in a subtitle, the search engine in `extract_anki_context` evaluates candidates based on their proximity to the pivot. Because the pivot is currently centered on the line, it often locks onto the geometrically central instance rather than the one the user actually clicked. This results in the wrong sentence being exported to Anki, leading to broken context or duplicated highlights.

## What Changes
- **Pivot Calculation Logic**: Refactor the math in `dw_anki_export_selection` (for range and point exports) and `ctrl_commit_set` (for multi-word non-contiguous sets) to calculate the byte offset of the specific `logical_idx` being exported.
- **Marker Injection**: Use a marker-based approach during context reconstruction to find the exact character position of the target word after ASS tags have been stripped and spaces collapsed.

## Capabilities

### New Capabilities
- None.

### Modified Capabilities
- `drum-window-indexing`: Refine the **Pivot-Point Anchoring** requirement to ensure it is implemented using precise character-offset calculation from the user's specific focus point rather than a geometric line center.

## Impact
- **Affected Code**: `scripts/lls_core.lua`, specifically `dw_anki_export_selection` and `ctrl_commit_set`.
- **APIs**: No external API changes, but internal data flow between selection event handlers and the Anki export engine will be tightened.
- **Performance**: Negligible impact; the calculation occurs only during a user-initiated export event.
