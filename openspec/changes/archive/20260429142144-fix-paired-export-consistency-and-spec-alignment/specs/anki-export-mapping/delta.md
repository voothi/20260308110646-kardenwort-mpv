# Delta: anki-export-mapping

## ADDED Requirements

### Requirement: Sentence Punctuation Restoration
The export system SHALL ensure that phrases resembling complete sentences maintain their terminal punctuation (., !, ?) in the exported term field, regardless of the selection mode (Yellow or Pink).

#### Scenario: Exporting a paired sentence fragment
- **GIVEN** a paired (Pink) selection that forms a phrase starting with an uppercase letter
- **AND** the original subtitle segment contained trailing punctuation at the end of the phrase's final word
- **WHEN** the export is triggered
- **THEN** the system SHALL append the terminal punctuation to the exported term if it is not already present.
- **AND** this behavior SHALL be identical to the existing standard selection (Yellow) export logic.
