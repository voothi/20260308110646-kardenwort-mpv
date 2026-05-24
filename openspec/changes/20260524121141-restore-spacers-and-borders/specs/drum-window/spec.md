## MODIFIED Requirements

### Requirement: Drum Window Unified Styling
The Drum Window SHALL allow explicit control over its appearance (font name, size, weight/boldness, background transparency, line height, and edge safe margins) via script options.

#### Scenario: Background Opacity Alignment
- **WHEN** the `dw_bg_opacity` and `dw_text_opacity` configurations are adjusted
- **THEN** the system SHALL apply the corresponding Alpha values (`\4a` and `\1a`) to the Window's localized background boxes and text respectively.

#### Scenario: Visual Normalization
- **WHEN** the user configures `dw_font_size`, `dw_border_size`, or `dw_shadow_offset`
- **THEN** the Drum Window SHALL apply these precisely to the rendering block, allowing the user to visually normalize the monospace interface to match the proportional Drum Mode interface.

#### Scenario: Unified Font and Weight
- **WHEN** the user configures `dw_font_name` or `dw_font_bold`
- **THEN** the Drum Window SHALL apply these font and weight settings to the text rendering, ensuring a consistent aesthetic across all mpv UI layers.

#### Scenario: Wrap Line Spacing and Margins
- **WHEN** the user configures `dw_wrap_line_height_mul` or `dw_edge_margin`
- **THEN** the Drum Window SHALL apply the custom line-height scaling for wrapped lines and ensure the clamped text block leaves at least `dw_edge_margin` pixels of safe space at screen boundaries.
