## ADDED Requirements

### Requirement: Cyrillic Suppression in Primary Track
The subtitle import system SHALL detect and skip lines containing Cyrillic characters when loading content for the primary reading track in the Drum Window.

#### Scenario: Loading mixed .ass file
- **WHEN** the system parses a `Dialogue:` line from an `.ass` file
- **AND** the line contains Cyrillic characters
- **THEN** the system SHALL exclude this line from the primary track buffer.
