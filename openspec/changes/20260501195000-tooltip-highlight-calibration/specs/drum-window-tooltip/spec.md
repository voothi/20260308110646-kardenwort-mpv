## MODIFIED Requirements

### Requirement: Tooltip Styling Unification
The Tooltip system SHALL support the standard suite of visual parameters (font name, font size, bg opacity, text color, boldness, etc.) following the project's unified schema to ensure stylistic parity with the parent display. Additionally, it SHALL support independent selection and multi-word highlight colors to allow for distinct visual calibration.

#### Scenario: Stylistic Parity
- **WHEN** the user modifies `tooltip_bg_opacity`, `tooltip_font_size`, or `tooltip_font_name`
- **THEN** the tooltip rendering engine SHALL apply these values to the OSD overlay using standardized ASS tags, matching the visual weight and typography of the Drum Window and Drum Mode.

#### Scenario: Unified Boldness
- **WHEN** the `tooltip_font_bold` option is toggled
- **THEN** the tooltip text SHALL render with the corresponding boldness state, synchronized with the user's preference for the active display mode.

#### Scenario: Independent Selection Calibration
- **WHEN** the user modifies `tooltip_highlight_color` or `tooltip_ctrl_select_color` in `mpv.conf`
- **THEN** the tooltip rendering engine SHALL use these specific colors for word highlighting and selection markers, independent of the values set for `dw_highlight_color` or `dw_ctrl_select_color`.
