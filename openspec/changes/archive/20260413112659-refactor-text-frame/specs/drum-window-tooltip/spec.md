## MODIFIED Requirements

### Requirement: Tooltip Positioning and Wrapping
The tooltip SHALL not overflow standard width or overlap the drum window destructively.

#### Scenario: Rendering translation box
- **WHEN** the tooltip is generated
- **THEN** the system SHALL anchor it near the right screen edge `{\an6}`
- **AND** the system SHALL enforce character width/wrapping constraints to limit infinite horizontal expansion
- **AND** the system SHALL apply a stylized localized background box with a configurable opacity (`tooltip_bg_opacity`).

### Requirement: Tooltip Styling Unification
The Tooltip system SHALL support the standard suite of visual parameters (`font_size`, `bg_opacity`, `text_color`, `bold`, etc.) following the project's unified schema.

#### Scenario: Stylistic Parity
- **WHEN** the user modifies `tooltip_bg_opacity` or `tooltip_font_size`
- **THEN** the tooltip rendering engine SHALL apply these values to the OSD overlay using standardized ASS tags, matching the visual weight of the Drum Window and Drum Mode.
