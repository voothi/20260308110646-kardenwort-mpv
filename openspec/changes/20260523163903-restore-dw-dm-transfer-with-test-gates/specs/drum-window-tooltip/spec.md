## MODIFIED Requirements

### Requirement: Tooltip Styling Unification
The Tooltip system SHALL support the standard suite of visual parameters (font name, font size, bg opacity, text color, boldness, line height, and DM/DW transparency guards) following the project's unified schema, and SHALL explicitly track local font variables at render-time to ensure stylistic parity and rendering stability.

#### Scenario: Stylistic Parity
- **WHEN** the user modifies `tooltip_bg_opacity`, `tooltip_font_size`, or `tooltip_font_name`
- **THEN** the tooltip rendering engine SHALL apply these values to the OSD overlay using standardized ASS tags, matching the visual weight and typography of the Drum Window and Drum Mode.

#### Scenario: Unified Boldness
- **WHEN** the `tooltip_font_bold` option is toggled
- **THEN** the tooltip text SHALL render with the corresponding boldness state, synchronized with the user's preference for the active display mode.

#### Scenario: Variable Resolution and Formatting Stability
- **WHEN** the translation tooltip is being formatted and drawn (`draw_dw_tooltip`)
- **THEN** the system SHALL resolve and apply local variables for font size (`fs`) and line height tracking
- **AND** the system SHALL render the OSD block without Lua formatting exceptions or nil-variable formatting failures.

## ADDED Requirements

### Requirement: DM Background-Box Transparency Neutrality
When Drum Mode is active (`FSM.DRUM_WINDOW == "OFF"`) and global OSD border style is `background-box`, tooltip rendering SHALL avoid double-dark layering by neutralizing per-line shadow/background alpha while keeping the global background-box contribution.

#### Scenario: DM Tooltip Transparency Guard
- **WHEN** the tooltip renderer builds DW/DM tooltip lines under DM with `background-box`
- **THEN** the tooltip background rectangle alpha SHALL switch to fully transparent (`FF`) for the local card
- **AND** each tooltip line SHALL include neutralized `\3a` and `\4a` alpha tags to prevent additional dark stacking.

### Requirement: Tooltip Degradation Resistance
The tooltip renderer SHALL remain stable under long wrapped subtitles and scrolling transitions by preserving consistent line-height math and cache invalidation behavior.

#### Scenario: Wrapped Tooltip Remains Stable During Scroll
- **WHEN** a long translation wraps into multiple visual lines and the user scrolls/navigates
- **THEN** tooltip layout calculations SHALL keep visual alignment with the target line
- **AND** tooltip output SHALL not collapse, disappear unexpectedly, or render malformed ASS fragments.
