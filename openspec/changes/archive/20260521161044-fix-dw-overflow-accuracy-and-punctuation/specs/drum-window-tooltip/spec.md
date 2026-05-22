## MODIFIED Requirements

### Requirement: Tooltip Styling Unification
The Tooltip system SHALL support the standard suite of visual parameters (font name, font size, bg opacity, text color, boldness, line height, etc.) following the project's unified schema, and SHALL explicitly track local font variables at render-time to ensure stylistic parity and absolute rendering stability.

#### Scenario: Stylistic Parity
- **WHEN** the user modifies `tooltip_bg_opacity`, `tooltip_font_size`, or `tooltip_font_name`
- **THEN** the tooltip rendering engine SHALL apply these values to the OSD overlay using standardized ASS tags, matching the visual weight and typography of the Drum Window and Drum Mode.

#### Scenario: Unified Boldness
- **WHEN** the `tooltip_font_bold` option is toggled
- **THEN** the tooltip text SHALL render with the corresponding boldness state, synchronized with the user's preference for the active display mode.

#### Scenario: Variable Resolution and Formatting Stability
- **WHEN** the translation tooltip is being formatted and drawn (`draw_dw_tooltip`)
- **THEN** the system SHALL resolve and apply local variables for font size (`fs`) and line height tracking
- **AND** the system SHALL render the OSD block without throwing Lua formatting exceptions or encountering nil variables.
