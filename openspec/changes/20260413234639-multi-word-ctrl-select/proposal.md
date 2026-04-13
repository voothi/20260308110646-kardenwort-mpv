## Why

When learning German and English, users frequently need to mark **multi-word constructs** — German separable-prefix verbs (e.g., *aufräumen* → *räum … auf*) and English phrasal verbs (e.g., *look up*, *put off*) — where individual word selection is insufficient. The current interaction model does not support non-contiguous word selection, forcing users to manually reconstruct compound forms from single-word exports or skip saving them entirely.

## What Changes

- **New gesture: Ctrl+LMB click** accumulates a set of individually-clicked words into a pending multi-word selection (yellow temporary highlight).
- **New gesture: Ctrl+MMB click on a word already in the Ctrl-selection** commits the accumulated word set as a saved highlight (orange persistent highlight), mimicking the existing MMB release-to-export contract but for the discrete multi-pick workflow.
- **Disambiguation rule**: Ctrl+MMB on a word that is NOT part of the current Ctrl-selection is treated as a plain MMB export on that single word — retaining backward compatibility with the existing single-click MMB behavior.
- Releasing Ctrl without clicking MMB discards the accumulated pending selection and clears yellow highlights.
- Saved Ctrl-selections are stored in the same TSV as all other exports and are re-highlighted in the standard saved color (orange) on subsequent renders.
- The yellow in-progress highlight color is distinct from existing selection colors (red drag, orange saved) to avoid visual ambiguity.

## Capabilities

### New Capabilities

- `ctrl-multiselect`: Multi-word non-contiguous selection via Ctrl+LMB click accumulation and Ctrl+MMB commit within the Drum Window.

### Modified Capabilities

- `lls-mouse-input`: New Ctrl modifier state must be tracked and routed to the accumulator; existing LMB/MMB gesture logic must be guarded against Ctrl interference.
- `mmb-drag-export`: The Single-Click Selection Commitment (SCM) scenario must be updated to distinguish between Ctrl+MMB (route to accumulator commit) and plain MMB (retain existing behavior).

## Impact

- **`lls_dw.lua`** (Drum Window input handler): Ctrl key state detection, LMB click-accumulate path, MMB-with-Ctrl commit path.
- **`lls_core.lua`** (export & highlight logic): Accept a sorted word-index list instead of a contiguous range; compose the exported term as space-joined words from the list.
- **`lls_highlight.lua`** (renderer): Recognize the new `ctrl-pending` highlight state and apply the yellow color token; no structural renderer change required beyond a new color tier.
- **`mpv.conf`** (config): Optional `ctrl_select_color` key for the yellow pending highlight color (default: `#FFE066`).
- Existing drag-LMB and MMB behaviors remain fully intact.
