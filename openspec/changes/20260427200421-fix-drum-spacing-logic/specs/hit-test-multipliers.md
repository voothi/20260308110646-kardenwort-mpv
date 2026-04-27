## ADDED Requirements

### Requirement: Cross-Mode Parity
All `_block_gap_mul` settings (drum, srt, dw) must be applied to the visual separator in their respective rendering functions.

#### Scenario: Switching Rendering Modes
- **WHEN** the user toggles between Regular and Drum Mode
- **THEN** the visual spacing must update to reflect the active mode's `_block_gap_mul` and `_vsp` settings, maintaining synchronization with hit-testing.
