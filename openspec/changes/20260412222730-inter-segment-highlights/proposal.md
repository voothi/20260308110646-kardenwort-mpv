## Why

Currently, the exact phrase matching engine is segment-bound. If a highlighted phrase (e.g., "falsch sind") is spread across two different subtitle blocks, the system fails to recognize the sequence, resulting in missing highlights. This change addresses this "edge case" which is actually common in news broadcasts and dialogue.

## What Changes

- **Inter-Segment Sequence Checking**: Refactor the highlighter matching engine to allow sequence verification to look into adjacent subtitle segments (previous/next).
- **Buffer-Aware Rendering**: Ensure that both the Drum and Drum Window modes provide the necessary subtitle buffer context to the matching engine.

## Capabilities

### New Capabilities
- `inter-segment-highlighter`: Capability to verify word sequences across subtitle segment boundaries by buffering adjacent subtitle text.

### Modified Capabilities
- `anki-highlighter`: Update the matching requirement to support multi-segment phrases without losing context strictness.

## Impact

- `lls_core.lua`: Core logic update in `calculate_highlight_stack` and the loop structures in `format_sub` and `draw_dw`.
- No impact on `mpv.conf` or external dependencies.
