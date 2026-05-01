## Why

Long translated (secondary) subtitles in the Drum Window tooltip currently do not handle line wrapping, leading to visual overflow and poor readability when translations are long. This change implements "transfer" (word-wrapping) for these subtitles to match the polished presentation of the primary subtitles in Drum Mode.

## What Changes

- **Tooltip Word Wrapping**: Implement a token-based wrapping engine for secondary subtitles within the `draw_dw_tooltip` function.
- **Dynamic Layout Height**: Update the tooltip's vertical positioning and boundary clamping logic to calculate the total block height based on the number of wrapped visual lines rather than just logical subtitle counts.
- **Visual Consistency**: Align the wrapping behavior, spacing, and font heuristic usage with the existing Drum Window main subtitle logic.

## Capabilities

### New Capabilities
- `tooltip-wrapping`: Implements visual line wrapping and dynamic layout for the Drum Window translation tooltip.

### Modified Capabilities
- `subtitle-rendering-spec`: Extends the subtitle presentation requirements to ensure that secondary tracks in windowed modes adhere to the same wrapping and layout invariants as primary tracks.

## Impact

- `scripts/lls_core.lua`: Modifies the tooltip rendering pipeline and layout calculations.
- `openspec/specs/subtitle-rendering-spec`: Updates the canonical specification for subtitle presentation.
