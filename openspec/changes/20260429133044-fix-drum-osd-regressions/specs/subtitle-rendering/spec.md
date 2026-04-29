## MODIFIED Requirements

### Requirement: Automatic Line Wrapping (SRT & Drum)
The OSD rendering engine SHALL automatically wrap subtitle lines that exceed the visual safe area (1860px) into multiple vertical lines to prevent text from bleeding off the screen.

#### Scenario: Long Sentence Wrapping
- **WHEN** an SRT subtitle contains a sentence longer than 1860px.
- **THEN** it SHALL be split into two or more visual lines.
- **AND** each visual line SHALL be centered horizontally.
- **AND** the system SHALL maintain accurate hit-testing (mouse interactivity) for every word on every wrapped visual line.

#### Scenario: Empty Subtitle Slot Preservation
- **WHEN** a context subtitle entry has empty text (e.g., a gap-filler line)
- **THEN** the rendering engine SHALL still reserve a vertical slot equal to `(font_size * line_height_mul) + vsp` for that entry.
- **AND** the slot SHALL produce no visible ASS text output.
- **AND** the total OSD block height SHALL be consistent regardless of whether context subtitles are empty or not.

### Requirement: Inter-Subtitle Gap Calculation Source
The gap inserted between two adjacent rendered subtitles in the OSD block SHALL be calculated using the font size of the subtitle that **just finished rendering** (the previous one), not the subtitle about to be rendered next.

#### Scenario: Active-to-Context Transition
- **GIVEN** the active subtitle uses `drum_active_size_mul = 1.3` and context subtitles use `drum_context_size_mul = 1.0`
- **WHEN** the gap is calculated between the active subtitle (bottom) and the next context subtitle
- **THEN** `calculate_sub_gap` SHALL receive the **active** subtitle's effective font size (`font_size * 1.3`)
- **AND** the resulting gap height SHALL match the visual spacing produced by the ASS `\\vsp` separator tag.

#### Scenario: Context-to-Active Transition
- **GIVEN** the active subtitle uses `drum_active_size_mul = 1.3` and context subtitles use `drum_context_size_mul = 1.0`
- **WHEN** the gap is calculated between a context subtitle (above) and the active subtitle below it
- **THEN** `calculate_sub_gap` SHALL receive the **context** subtitle's effective font size (`font_size * 1.0`)
- **AND** the resulting gap height SHALL be smaller than the gap after the active line.
