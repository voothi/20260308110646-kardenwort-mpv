# drum-context Specification

## Purpose
TBD - created by archiving change 20260309002123-release-v1-0-0. Update Purpose after archive.
## Requirements
### Requirement: Visualization of Context Lines
The system SHALL display the preceding and succeeding subtitle lines around the active dialogue when Drum Context Mode is enabled.

#### Scenario: Displaying context
- **WHEN** Drum Context Mode is active ('c')
- **THEN** the system SHALL render the previous and next lines with dimmed/transparent highlights relative to the active line.

### Requirement: ASS Protection
The system SHALL automatically disable Drum Context Mode when encountering complex subtitle formatting to prevent rendering artifacts.

#### Scenario: Complex subtitle detected
- **WHEN** a subtitle track contains complex ASS formatting
- **THEN** Drum Context Mode SHALL be bypassed.

