## ADDED Requirements

### Requirement: Anki Metadata Mapping
Discovered media source URLs SHALL be made available to the Anki export engine via a standardized keyword.

#### Scenario: source_url Field Mapping
- **WHEN** a media source URL is successfully discovered and cached
- **AND** the `anki_mapping.ini` contains a field mapped to the `source_url` keyword
- **THEN** the system SHALL populate that field with the discovered URL during every export.
