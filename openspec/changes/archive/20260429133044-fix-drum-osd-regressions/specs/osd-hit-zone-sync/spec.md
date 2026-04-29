## MODIFIED Requirements

### Requirement: Unified Gap Calculation
- The gap between two subtitles (sub-gap) must be calculated consistently across all renderers.
- **Double Gap**: `gap = (font_size * line_height_mul) + (font_size * block_gap_mul) + vsp`.
- **Single Gap**: `gap = 0` (The natural vertical advance of a single \N is assumed to match the `line_height_mul` calibration).
- This ensures that `block_gap_mul` acts as a specific "block-to-block" adjustment that does not interfere with the tightly-packed internal lines of a single-gap mode.
- **Source Font Size**: The `font_size` used for this calculation SHALL be the effective font size of the preceding subtitle in the rendering sequence.

#### Scenario: Gap Consistency after Large Subtitle
- **WHEN** a subtitle with an active size multiplier (e.g., 1.3x) is followed by a standard context subtitle
- **THEN** the logical gap height SHALL be calculated using the 1.3x size
- **AND** the physical hit-zones SHALL be shifted by this exact amount to maintain parity with the visual ASS rendering.

### Requirement: OSD Hit-Zone Generation Efficiency
The generation of logical hit-zones and the associated character-width calculations SHALL only be performed when interactive features are requested.

#### Scenario: Non-Interactive Rendering
- **WHEN** `Options.osd_interactivity` is set to `false`
- **OR** when the calling function does not provide a `hit_zones` table
- **THEN** the system SHALL skip the population of hit-zones
- **AND** it SHALL bypass the detailed word-wrapping width calculations if they are only needed for hit-zone geometry.
