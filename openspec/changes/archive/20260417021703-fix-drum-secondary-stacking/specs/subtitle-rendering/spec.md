## ADDED Requirements

### Requirement: Independent Manual Positioning for Multiple Tracks
The system SHALL respect the user's manual subtitle position adjustments even when multiple subtitle tracks are active in Drum Mode.

#### Scenario: Manual Adjustment via Hotkeys
- **GIVEN** Drum Mode C is active with two tracks (Primary and Secondary)
- **WHEN** the user presses `r`/`t` or `Shift+r`/`Shift+t` to adjust subtitle positions
- **THEN** both the primary and secondary OSD blocks SHALL move to the positions requested by the user.
- **AND** the script SHALL NOT automatically overwrite these positions in the rendering loop.

#### Scenario: Decoupled Track Stacking
- **GIVEN** Secondary Sub Pos is toggled to "BOTTOM"
- **THEN** the system SHALL use a default position that avoids immediate overlap with the primary track.
