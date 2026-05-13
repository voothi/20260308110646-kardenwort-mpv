## MODIFIED Requirements

### Requirement: Dual-Lane Drum Scroll Synchronization
When manual drum scrolling is active, lower and upper subtitle lanes SHALL move in synchronized viewport context.

#### Scenario: Primary-only scroll behavior
- **GIVEN** only primary subtitles are active
- **WHEN** the user scrolls in drum mode
- **THEN** the viewport SHALL scroll relative to the active primary index
- **AND** manual scroll state SHALL remain stable until explicit follow-player reset.

#### Scenario: Dual-track synchronized scroll
- **GIVEN** primary and secondary subtitle tracks are both active
- **AND** manual viewport mode is active (`DW_FOLLOW_PLAYER == false`)
- **WHEN** the user scrolls by one step
- **THEN** both lanes SHALL shift by an equivalent logical viewport offset
- **AND** neither lane SHALL remain pinned to playhead-follow mode independently.

#### Scenario: Secondary-only fallback
- **GIVEN** only secondary subtitles are active
- **WHEN** the user scrolls in drum mode
- **THEN** the viewport SHALL scroll relative to the active secondary index without requiring a primary index anchor.

#### Scenario: Zero-scrolloff clamping in compact viewport
- **GIVEN** drum mode is ON and drum window is OFF
- **AND** `drum_scrolloff` is `0`
- **AND** the effective DM mini viewport is compact (including one-line configuration)
- **WHEN** manual scroll is applied repeatedly in either direction
- **THEN** computed scroll margin SHALL be clamped to a non-negative value
- **AND** viewport movement SHALL NOT use a `-1` margin path
- **AND** pointer/context alignment SHALL remain stable.
