## MODIFIED Requirements

### Requirement: Anki Data Source Resolution
The system SHALL support the following additional keyword in `anki_mapping.ini` to resolve TSV field values:

- **keyword**: `source_url`
- **resolution**: The dynamic URL discovered via the `source-url-discovery` mechanism. If no URL is discovered, it SHALL resolve to an empty string.

#### Scenario: Mapping to source_url
- **WHEN** an entry in `[fields_mapping.*]` is set to `source_url`
- **AND** a valid URL has been discovered in the media directory
- **THEN** that URL SHALL be populated in the corresponding TSV column during export.
