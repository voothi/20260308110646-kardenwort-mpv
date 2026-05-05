## ADDED Requirements

### Requirement: Supported Secondary Track Filtering
The secondary subtitle cycle MUST only include external subtitle tracks that are supported by the Kardenwort immersion logic.

#### Scenario: Normal Cycle
- **WHEN** Pressing `Shift+c`
- **THEN** The player MUST cycle only through external subtitle files (e.g., .srt, .ass) and the "OFF" state.

#### Scenario: Embedded Track Suppression
- **WHEN** Media contains both internal (embedded) and external subtitle tracks
- **THEN** Pressing `Shift+c` MUST automatically skip all internal tracks.

#### Scenario: Primary Track Conflict Avoidance
- **WHEN** A specific external track is currently active as the primary subtitle (`sid`)
- **THEN** Pressing `Shift+c` MUST NOT select that same track as the secondary subtitle, jumping to the next available supported track instead.

### Requirement: OSD Transparency
The OSD MUST inform the user when tracks are being hidden from the cycle.

#### Scenario: Informative OSD Suffix
- **WHEN** Built-in tracks are detected in the media file
- **THEN** The secondary subtitle OSD message MUST include a `[X built-in hidden]` suffix.
