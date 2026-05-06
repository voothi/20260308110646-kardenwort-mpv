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

#### Scenario: Secondary subtitle toggle does not suppress tooltip anchor 20260506200831
- **WHEN** the user toggles secondary subtitles via `Shift+C` so the secondary subtitle track becomes hidden or `OFF`
- **AND** Drum Mode primary subtitle tooltip rendering is otherwise eligible
- **THEN** the tooltip overlay SHALL remain available for primary subtitle interactions
- **AND** tooltip content resolution SHALL NOT depend on current secondary subtitle visibility state.
