## MODIFIED Requirements

### Requirement: Tooltip Styling Unification
The Tooltip system SHALL support the standard suite of visual parameters (font name, font size, bg opacity, text color, boldness, and Cyrillic character width coefficients) following the project's unified schema to ensure stylistic parity with the parent display.

#### Scenario: Stylistic Parity
- **WHEN** the user modifies `tooltip_bg_opacity`, `tooltip_font_size`, or `tooltip_font_name`
- **THEN** the tooltip rendering engine SHALL apply these values to the OSD overlay using standardized ASS tags, matching the visual weight and typography of the Drum Window and Drum Mode.

#### Scenario: Unified Boldness
- **WHEN** the `tooltip_font_bold` option is toggled
- **THEN** the tooltip text SHALL render with the corresponding boldness state, synchronized with the user's preference for the active display mode.

#### Scenario: Cyrillic Character Width Calibration
- **WHEN** a Cyrillic translation is rendered in the tooltip
- **THEN** the system SHALL compute horizontal visual envelopes using a calibrated coefficient of at least `0.52 * font_size` per glyph to prevent boundary truncation.

### Requirement: RMB Interaction Preservation
The system SHALL preserve legacy Right Mouse Button (RMB) interaction patterns for tooltips, and center tooltips horizontally during Drum Mode (DM) active ticks.

#### Scenario: Tooltip remains visible and follows focus while RMB is held
- **GIVEN** the Drum Window tooltip is configured for `CLICK` mode
- **WHEN** the user presses and holds RMB and moves the mouse across multiple subtitle lines
- **THEN** the tooltip SHALL dynamically update to show information for the line currently under the mouse pointer.

#### Scenario: Tooltip dismisses when mouse focus leaves pinned line (CLICK Mode)
- **GIVEN** the Drum Window tooltip is in `CLICK` mode (no active keyboard force)
- **WHEN** the user right-clicks a line to pin the tooltip
- **AND** the user then moves the mouse focus to a different subtitle line
- **THEN** the pinned tooltip SHALL be dismissed.

#### Scenario: Centering Tooltip in Drum Mode
- **GIVEN** Drum Mode is active and Drum Window is OFF
- **WHEN** the translation tooltip is displayed
- **THEN** the tooltip text, hit zones, and vector background box SHALL be horizontally centered at `X = 960` (with `\an8` alignment) and vertically aligned at the secondary subtitle area.
