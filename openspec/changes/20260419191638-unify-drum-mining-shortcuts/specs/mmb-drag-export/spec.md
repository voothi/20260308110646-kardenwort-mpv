## MODIFIED Requirements

### Requirement: MMB Release-to-Export
The Middle Mouse Button (MMB) in the Drum Window SHALL automatically trigger the Anki export process upon release. The output format SHALL be determined by the `anki-export-mapping` configuration. 
Additionally, the system SHALL check if the drag operation started on a paired (pink) word; if so, it SHALL commit the paired set on release rather than starting a new contiguous export.

#### Scenario: Auto-export on release
- **WHEN** the user releases MMB after selecting a phrase
- **THEN** the phrase SHALL be saved to Anki (green highlight) immediately according to the dynamic mapping specified in `anki_mapping.ini`.

#### Scenario: Drag release on paired word commit
- **WHEN** the user release MMB over a word that was already part of a paired (pink) set
- **THEN** the system SHALL commit the entire set (`ctrl_commit_set`) upon release.
