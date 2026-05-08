## ADDED Requirements

### Requirement: UI - Tooltip Hit-Zones and Highlight Aesthetics
Tooltips and highlights must be visually accurate and interactive as per archives 20260503190627 and 20260502135022.

#### Scenario: Tooltip Hit-Zone Accuracy
- **WHEN** the mouse hovers over a word in the Drum Window.
- **THEN** the hit-zone must accurately trigger the tooltip without "ghost" interference from adjacent elements.

### Requirement: System - SRT Hardening, Logging, and Session Resume
Core system utilities must be robust and efficient as per archives 20260505004553, 20260502082941, and 20260502005934.

#### Scenario: Session Resume
- **WHEN** mpv is started with the `resume-last-file` script.
- **THEN** it should automatically load the last played file and seek to the last position.

#### Scenario: Smart Logging
- **WHEN** the system is running normally.
- **THEN** it should suppress redundant "spam" messages while maintaining diagnostic capability.
