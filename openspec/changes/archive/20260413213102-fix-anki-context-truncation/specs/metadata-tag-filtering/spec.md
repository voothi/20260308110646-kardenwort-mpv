## ADDED Requirements

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
