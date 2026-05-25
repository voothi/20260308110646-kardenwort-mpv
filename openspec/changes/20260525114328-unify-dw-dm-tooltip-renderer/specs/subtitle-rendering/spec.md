## ADDED Requirements

### Requirement: Custom OSD Tooltip Visual Uniformity
All Kardenwort custom OSD modes that can activate the translation tooltip SHALL use the shared tooltip visual contract for tooltip output.

#### Scenario: Styled SRT tooltip uses shared contract
- **GIVEN** Drum Mode is OFF
- **AND** Drum Window is OFF
- **AND** styled SRT custom OSD rendering is active
- **WHEN** the user activates the tooltip
- **THEN** the tooltip SHALL use the same card/text/border/background contract as the DW and DM tooltip paths.

#### Scenario: Drum tooltip uses shared contract
- **GIVEN** Drum Mode is ON
- **AND** Drum Window is OFF
- **WHEN** the user activates the tooltip by keyboard or mouse
- **THEN** the tooltip overlay SHALL use the shared tooltip visual contract
- **AND** it SHALL preserve Drum Mode target resolution from primary hit-zones.

#### Scenario: Drum Window tooltip uses shared contract
- **GIVEN** Drum Window is active
- **WHEN** the user activates the tooltip by keyboard or mouse
- **THEN** the tooltip overlay SHALL use the shared tooltip visual contract
- **AND** it SHALL preserve Drum Window target resolution from DW hit-zones.

### Requirement: Tooltip Rendering Regression Coverage
Acceptance coverage SHALL validate tooltip ASS output for DW, DM, and styled SRT modes under configurations that previously caused visual divergence.

#### Scenario: Background-box regression guard
- **GIVEN** global `osd-border-style` is `background-box`
- **WHEN** tooltip ASS output is queried for DW, DM, and styled SRT modes
- **THEN** the output SHALL contain the shared measured-card event
- **AND** it SHALL NOT contain active native per-line background-box styling for tooltip text events.

#### Scenario: Style tag ordering regression guard
- **WHEN** tooltip text event ASS is generated
- **THEN** any native background-box neutralization SHALL appear after the border/shadow alpha tags that would otherwise re-enable native boxes
- **AND** tests SHALL fail if `{\\3a...}` or `{\\4a...}` tags are appended after the final neutralization in the same text event.
