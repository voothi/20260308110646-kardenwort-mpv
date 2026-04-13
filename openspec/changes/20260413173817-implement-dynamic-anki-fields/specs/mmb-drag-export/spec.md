## MODIFIED Requirements

### Requirement: MMB Release-to-Export
The Middle Mouse Button (MMB) in the Drum Window SHALL automatically trigger the Anki export process upon release. The output format SHALL be determined by the `anki-export-mapping` configuration.

#### Scenario: Auto-export on release
- **WHEN** the user releases MMB after selecting a phrase
- **THEN** the phrase SHALL be saved to Anki (green highlight) immediately according to the dynamic mapping specified in `mpv.conf`.
