## MODIFIED Requirements

### Requirement: Visualization of Context Lines
The system SHALL display the preceding and succeeding subtitle lines around the active dialogue when Drum Context Mode is enabled, and allow punctuation selection eligibility.

#### Scenario: Displaying context
- **WHEN** Drum Context Mode is active ('c')
- **THEN** the system SHALL render the previous and next lines with dimmed/transparent highlights relative to the active line.

#### Scenario: Punctuation Selection Eligibility
- **WHEN** the primary track is in Drum Mode or Drum Window Mode
- **THEN** trailing punctuation marks (e.g., `.`, `?`, `!`) SHALL be treated as selectable tokens, allowing mouse clicks to highlight, pin, or export them just like standard alphanumeric words.
