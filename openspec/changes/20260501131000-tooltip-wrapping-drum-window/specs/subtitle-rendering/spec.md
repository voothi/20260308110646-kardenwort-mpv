## MODIFIED Requirements

### Requirement: Automatic Line Wrapping (SRT, Drum & Tooltip)
The OSD rendering engine SHALL automatically wrap subtitle lines that exceed the visual safe area into multiple vertical lines to prevent text from bleeding off the screen.
- For Primary (SRT & Drum) subtitles, the safe area is defined as 1860px.
- For Tooltip (Secondary) subtitles, the safe area is defined as 1400px.

#### Scenario: Long Sentence Wrapping
- **WHEN** a subtitle (Primary or Secondary Tooltip) contains a sentence longer than its respective safe area.
- **THEN** it SHALL be split into two or more visual lines.
- **AND** each visual line SHALL be aligned according to its mode's anchor (Center for Primary, Right for Tooltip).
- **AND** the system SHALL maintain accurate hit-testing (where applicable) for every word on every wrapped visual line.
