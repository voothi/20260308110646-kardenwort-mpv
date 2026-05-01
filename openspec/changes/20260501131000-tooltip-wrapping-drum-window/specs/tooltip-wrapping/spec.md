## ADDED Requirements

### Requirement: Automatic Tooltip Line Wrapping
The Drum Window translation tooltip SHALL automatically wrap secondary subtitle lines that exceed a visual safe area to prevent text from bleeding off the screen.

#### Scenario: Long Translation Wrapping
- **WHEN** a secondary subtitle in the tooltip contains a sentence longer than the defined maximum width (1400px)
- **THEN** it SHALL be split into two or more visual lines within the subtitle block.
- **AND** the system SHALL maintain visual consistency with the main Drum Window wrapping heuristic.

### Requirement: Multi-Line Tooltip Height Calculation
The tooltip rendering engine SHALL calculate the total vertical height of the tooltip block based on the aggregate number of visual lines across all logical subtitle entries.

#### Scenario: Centering Multi-Line Tooltips
- **GIVEN** a tooltip containing multiple secondary subtitles, some of which are wrapped into multiple lines
- **WHEN** the system calculates the `block_height` for vertical centering
- **THEN** it SHALL sum the heights of every visual line and inter-line gap.
- **AND** the final `osd_y` position SHALL ensure the entire multi-line block remains centered relative to the target primary subtitle line.
