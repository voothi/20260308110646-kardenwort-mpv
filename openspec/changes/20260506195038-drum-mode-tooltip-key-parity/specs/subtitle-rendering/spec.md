## ADDED Requirements

### Requirement: Drum Primary Tooltip Rendering
Subtitle rendering SHALL support tooltip extraction from Drum Mode primary subtitle hit-zones on the bottom subtitle stream.

#### Scenario: Tooltip extraction from primary hit-zone
- **WHEN** a Drum tooltip action targets a word in the active primary subtitle line
- **THEN** the renderer SHALL map the pointer to the corresponding token
- **AND** it SHALL render tooltip text derived from that token via the tooltip overlay.

### Requirement: Visibility-Safe Tooltip Rendering
Drum Mode tooltip rendering SHALL obey effective subtitle visibility and media compatibility guards.

#### Scenario: Global subtitles disabled
- **WHEN** effective subtitle visibility is disabled by global toggle state
- **THEN** Drum tooltip overlay SHALL not render
- **AND** any existing tooltip overlay buffer SHALL be cleared.
