## MODIFIED Requirements

### Requirement: Drum Window Unified Styling
The Drum Window SHALL allow explicit control over its appearance (font name, size, weight/boldness, background transparency, safe margins, and decoupled wrap spacing) via script options.

#### Scenario: Background Opacity Alignment
- **WHEN** the `dw_bg_opacity` and `dw_text_opacity` configurations are adjusted
- **THEN** the system SHALL apply the corresponding Alpha values (`\4a` and `\1a`) to the Window's localized background boxes and text respectively.

#### Scenario: Visual Normalization
- **WHEN** the user configures `dw_font_size`, `dw_border_size`, or `dw_shadow_offset`
- **THEN** the Drum Window SHALL apply these precisely to the rendering block, allowing the user to visually normalize the monospace interface to match the proportional Drum Mode interface.

#### Scenario: Unified Font and Weight
- **WHEN** the user configures `dw_font_name` or `dw_font_bold`
- **THEN** the Drum Window SHALL apply these font and weight settings to the text rendering, ensuring a consistent aesthetic across all mpv UI layers.

#### Scenario: Configurable Margins and Wrap Spacing
- **WHEN** the user configures `dw_edge_margin` or `dw_wrap_line_height_mul`
- **THEN** the system SHALL apply these options to adjust the viewport's safe-area padding and visual spacing between wrapped subtitle lines.

## ADDED Requirements

### Requirement: Drum Window Dynamic Positioning and Clamping
The system SHALL dynamically position the Drum Window layout block based on the visual center line and clamp it within physical screen boundaries to prevent text cutoff, leaving a customizable `dw_edge_margin` of safe padding at both top and bottom edges when the block height overflows the available viewport.

#### Scenario: Layout Block Centering and Boundary Clamping
- **WHEN** the visual subtitle layout height overflows the baseline screen height (1080px)
- **THEN** the system SHALL align the active focused line (`view_center`) with the vertical center of the screen
- **AND** the system SHALL clamp the block offset such that it does not scroll beyond the safe padding boundaries defined by `dw_edge_margin`.

### Requirement: Decoupled Intra-Subtitle Wrap Spacing
The system SHALL space wrapped visual lines within a single subtitle using `dw_wrap_line_height_mul` to avoid descender overlap for characters like `g`, `j`, and `y`, while preserving the inter-subtitle block gaps governed by `dw_line_height_mul`.

#### Scenario: Rendering Wrapped Lines with Custom Multiplier
- **WHEN** a subtitle line wraps into multiple visual lines
- **THEN** the spacing between these wrapped lines SHALL be calculated using the `dw_wrap_line_height_mul` value, ensuring appropriate clearance for descenders without altering the distance between adjacent subtitles.

### Requirement: Render-Cached Mouse Interaction
The system SHALL cache visual OSD coordinate bounding boxes in `FSM.DW_HIT_ZONES` during the drawing phase (`draw_dw`), and the mouse hit-tester (`dw_hit_test`) SHALL dispatch clicks directly against these cached zones to ensure 100% click-targeting accuracy and eliminate all accumulated vertical drift.

#### Scenario: Interaction Aligns Perfectly with Visual Render
- **WHEN** a mouse click or hover event occurs within the Drum Window
- **THEN** the system SHALL retrieve coordinates directly from `FSM.DW_HIT_ZONES` to determine the targeted word and line
- **AND** the interaction target SHALL align perfectly with the visually printed text coordinates.

### Requirement: Unified Drum Window Card Composition
The system SHALL render Drum Window text as one cohesive ASS dialogue block anchored with `\an5`, while still using dynamic block-top positioning logic for overflow clamping.

#### Scenario: Single Positioned Render Block
- **WHEN** Drum Window content is rendered under normal or overflow conditions
- **THEN** the final ASS payload SHALL contain a single primary `\pos(960, y)` anchor for the DW body
- **AND** the visible background/frame SHALL remain a unified card rather than fragmented per-line positioned blocks.
