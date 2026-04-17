## ADDED Requirements

### Requirement: German UTF-8 Localization
The normalization engine MUST accurately map German uppercase umlauts and sharp S to their lowercase equivalents to support case-insensitive matching in German media.

#### Scenario: Normalizing German words
- **WHEN** Normalizing "Große" or "Änderung"
- **THEN** The engine MUST produce "große" and "änderung".
