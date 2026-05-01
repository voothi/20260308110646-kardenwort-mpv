## MODIFIED Requirements

### Requirement: Multi-Mode Selection Calibration
The system SHALL support independent selection and multi-word highlight colors for all interaction modes (Drum Window, Tooltip, Drum Mode, SRT Mode) and tracks (Primary, Secondary) to allow for distinct visual calibration across diverse rendering contexts.

#### Scenario: Tooltip Selection Calibration
- **WHEN** the user modifies `tooltip_highlight_color` or `tooltip_ctrl_select_color` in `mpv.conf`
- **THEN** the tooltip rendering engine SHALL use these specific colors, independent of the Drum Window values.

#### Scenario: Drum Mode Track-Specific Calibration
- **WHEN** the user modifies `drum_pri_highlight_color` or `drum_sec_highlight_color`
- **THEN** the Drum Mode rendering engine SHALL apply the primary color to the top track and the secondary color to the bottom track.

#### Scenario: SRT Mode Track-Specific Calibration
- **WHEN** the user modifies `srt_pri_highlight_color` or `srt_sec_highlight_color`
- **THEN** the SRT Mode rendering engine SHALL apply the primary color to the main track and the secondary color to the translation track.

### Requirement: Independent Highlight Weight Calibration
The system SHALL support independent font-weight (bold/regular) toggles for highlights in all modes, ensuring manual selections can be set to "Premium" regular weight while database matches remain bold.

#### Scenario: Manual Selection Weight
- **WHEN** `tooltip_highlight_bold` is set to `no`
- **THEN** manual selections in the tooltip SHALL be rendered with regular weight (`\b0`).
- **AND** database matches (Priority 3) SHALL still respect `anki_highlight_bold`.
