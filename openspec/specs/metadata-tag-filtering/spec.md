# metadata-tag-filtering Specification

## Purpose
TBD - created by archiving change 20260413213102-fix-anki-context-truncation. Update Purpose after archive.
## Requirements
### Requirement: Automated Metadata Tag Filtering
The Anki export system SHALL automatically remove technical subtitle metadata tags enclosed in square brackets (e.g., `[musik]`, `[Lachen]`) from exported terms and sentences.

#### Scenario: Cleaning up sound effect tags
- **WHEN** a subtitle block containing the text `[musik] Die Luftfahrt` is processed for export
- **THEN** both the exported term and the resulting context sentence exclude the `[musik]` tag.

### Requirement: Configurable Tag Filtering
The system SHALL provide a configuration option to toggle metadata filtering.

#### Scenario: Toggling tag filtering
- **WHEN** `anki_strip_metadata` is set to `yes` in `mpv.conf`
- **THEN** tags are stripped during export.
- **WHEN** set to `no`, tags are preserved.

### Requirement: Selective Metadata Filtering for primary terms
When the system is set to strip metadata tags (e.g., `[musik]`), it SHALL NOT strip the content of the ONLY remaining tag in the exported term. Instead, it SHALL only strip the brackets themselves.

#### Scenario: Exporting a word in brackets
- **GIVEN** `anki_strip_metadata` is set to `yes`
- **WHEN** the user selects the word `[UMGEBUNG]`
- **THEN** the exported term SHALL be `UMGEBUNG`.

#### Scenario: Stripping secondary metadata
- **GIVEN** `anki_strip_metadata` is set to `yes`
- **WHEN** the user selects `[musik] Die Luftfahrt`
- **THEN** the exported term SHALL be `Die Luftfahrt`.


