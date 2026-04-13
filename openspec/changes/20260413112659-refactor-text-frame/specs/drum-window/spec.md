## MODIFIED Requirements

### Requirement: Drum Window Unified Styling
The Drum Window SHALL allow explicit control over its appearance (font size, weight, and background transparency) via script options, matching the parameters of other HUD components.

#### Scenario: Background Opacity Alignment
- **WHEN** the `dw_bg_opacity` and `dw_text_opacity` configurations are adjusted
- **THEN** the system SHALL apply the corresponding Alpha values (`\4a` and `\1a`) to the Window's localized background boxes and text respectively.

#### Scenario: Visual Normalization
- **WHEN** the user configures `dw_font_size`, `dw_border_size`, or `dw_shadow_offset`
- **THEN** the Drum Window SHALL apply these precisely to the rendering block, allowing the user to visually normalize the monospace interface to match the proportional Drum Mode interface.
