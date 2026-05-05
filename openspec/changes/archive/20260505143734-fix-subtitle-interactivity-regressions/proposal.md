## Why

This change addresses functional regressions in subtitle selection and immersion mode transitions:
1. **Selection Over-reach**: In non-Drum Mode (Regular OSD), mouse-based selection (MMB) often drags into adjacent subtitles due to unintended auto-scrolling triggers.
2. **Phrase Mode Jump**: Switching to `PHRASE` mode near subtitle boundaries causes a "Jerk Back" seek that triggers auto-play into the next segment.

## What Changes

- **Interactivity Guard**: `dw_mouse_auto_scroll` is now disabled when the Drum Window is OFF, preventing selection expansion on standard OSD subtitles.
- **State Synchronization**: `cmd_cycle_immersion_mode` now synchronizes `FSM.ACTIVE_IDX` during mode transitions to prevent phantom boundary detection.

## Capabilities

### Modified Capabilities
- `lls-mouse-input`: Added requirement for mode-aware auto-scroll suppression.
- `fsm-architecture`: Added requirement for state synchronization during immersion mode transitions.
- `dw-mouse-selection-engine`: Hardened boundary detection to prevent range expansion in OSD mode.

## Impact
- Affects `scripts/lls_core.lua`.
- Improves reliability of Anki exports and mode switching.
