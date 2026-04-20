# metadata-tag-filtering Specification

## Purpose
TBD - created by archiving change 20260413213102-fix-anki-context-truncation. Update Purpose after archive.

## Requirements

### Requirement: Automated Metadata Tag Filtering
The Anki export system SHALL automatically remove technical subtitle metadata tags enclosed in square brackets (e.g., `[musik]`, `[Lachen]`) from exported terms and sentences context.

#### Scenario: Cleaning up sound effect tags in context
- **WHEN** a subtitle block containing the text `[musik] Die Luftfahrt` is processed for export
- **THEN** the resulting context sentence excludes the `[musik]` tag.

### Requirement: Configurable Tag Filtering
The system SHALL provide a configuration option to toggle metadata filtering.

#### Scenario: Toggling tag filtering
- **WHEN** `anki_strip_metadata` is set to `yes` in `mpv.conf`
- **THEN** tags are stripped during export.
- **WHEN** set to `no`, tags are preserved.

### Requirement: Exact Granular Stripping for Primary Terms
When the system is set to strip metadata tags (e.g., `[musik]`), it SHALL NOT strip brackets from a multi-word or mixed selection containing brackets. The brackets SHALL ONLY be stripped from the `source_word` field if the *entire selection* consists of exactly one bracketed tag.

#### Scenario: Exporting a purely bracketed word
- **GIVEN** `anki_strip_metadata` is set to `yes`
- **WHEN** the user explicitly selects only `[UMGEBUNG]`
- **THEN** the exported term SHALL be `UMGEBUNG`.

#### Scenario: Exporting mixed text containing brackets
- **GIVEN** `anki_strip_metadata` is set to `yes`
- **WHEN** the user selects a range spanning `Ende [musik] Neu`
- **THEN** the exported term SHALL be `Ende [musik] Neu` (brackets are preserved to honor the exact user selection boundaries).
