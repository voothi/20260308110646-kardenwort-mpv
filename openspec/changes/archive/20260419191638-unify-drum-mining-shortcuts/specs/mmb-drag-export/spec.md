## ADDED Requirements

### Requirement: Smart MMB Release-to-Export
The Middle Mouse Button (MMB) in the Drum Window SHALL automatically detect the selection context upon release.
Additionally, the system SHALL check if the drag operation started on a paired (pink) word; if so, it SHALL commit the paired set on release rather than starting a new contiguous export.

#### Scenario: Drag release on paired word commit
- **WHEN** the user release MMB over a word that was already part of a pending paired set (Pink)
- **THEN** the system SHALL commit the entire set (`ctrl_commit_set`) upon release.
