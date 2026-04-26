## ADDED Requirements

### Requirement: Line-Specific Alpha in Drum Window
The system SHALL apply different transparency levels to the "active" subtitle line vs "context" subtitle lines within the Drum Window.

#### Scenario: Visual Emphasis in Window Mode
- **WHEN** the Drum Window is displayed.
- **AND** `dw_active_opacity` is "00" and `dw_context_opacity` is "30".
- **THEN** the active playback line (indicated by `FSM.DW_ACTIVE_LINE`) SHALL be fully opaque.
- **AND** all other lines in the window SHALL be rendered with "30" alpha (semi-transparent).

### Requirement: Configurable Fading
The transparency levels for active and context lines in the Drum Window MUST be user-configurable via standard script options.

#### Scenario: Disabling fading
- **WHEN** the user sets `dw_context_opacity` to "00" in `mpv.conf`.
- **THEN** all lines in the Drum Window SHALL be rendered with full saturation, matching the previous behavior.
