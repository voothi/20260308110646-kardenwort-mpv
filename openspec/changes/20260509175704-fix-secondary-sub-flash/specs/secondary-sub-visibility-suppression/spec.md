## ADDED Requirements

### Requirement: Immediate Secondary Subtitle Suppression
The system SHALL immediately set the `secondary-sub-visibility` mpv property to `false` when a secondary track is selected or changed, provided that the custom OSD rendering mode (Drum Mode or SRT custom font mode) is active.

#### Scenario: Switching secondary track in Drum Mode
- **WHEN** the user cycles to a new secondary subtitle track using `cmd_cycle_sec_sid` while `FSM.DRUM` is "ON"
- **THEN** the native `secondary-sub-visibility` SHALL be set to `false` synchronously before the track change is visually processed by the mpv core.

#### Scenario: Secondary track change via observer
- **WHEN** the `secondary-sid` mpv property changes and the custom OSD rendering is active
- **THEN** the system SHALL enforce `secondary-sub-visibility` as `false` within the property observer.

### Requirement: OSD Blockage Prevention
The system SHALL ensure that `drum_osd:update()` is called immediately after a secondary track change to prevent OSD "twitching" or temporary blockage.

#### Scenario: Immediate OSD update after track cycle
- **WHEN** a new secondary SID is selected via `cmd_cycle_sec_sid`
- **THEN** the system SHALL trigger an immediate OSD redraw to reflect the change without waiting for the next periodic tick.
