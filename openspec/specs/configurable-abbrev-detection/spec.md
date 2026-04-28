# configurable-abbrev-detection Specification

## Purpose
Allow users to customize the list of abbreviations and toggle heuristic-based detection to handle language-specific patterns.

## Requirements

### Requirement: User-Configurable Abbreviation List
The system SHALL provide a configuration option `anki_abbrev_list` allowing users to specify a space-separated list of abbreviations that should not trigger sentence boundaries.

#### Scenario: Custom abbreviation in config
- **WHEN** `anki_abbrev_list` contains `"viz."`
- **AND** a word in the subtitle is `"viz."`
- **THEN** `is_abbrev` SHALL return `true` for that word.

### Requirement: Smart Abbreviation Detection Toggle
The system SHALL provide a configuration option `anki_abbrev_smart` to enable or disable heuristic-based abbreviation detection (e.g., short lowercase patterns).

#### Scenario: Disabling smart detection
- **WHEN** `anki_abbrev_smart` is set to `false`
- **AND** a word matches a heuristic pattern (e.g., `"ca."`) but is NOT in `anki_abbrev_list`
- **THEN** `is_abbrev` SHALL return `false`.

### Requirement: Case-Insensitive Abbreviation Matching
The system SHALL perform abbreviation matching in a case-insensitive manner.

#### Scenario: Matching Mixed Case Abbreviation
- **WHEN** `anki_abbrev_list` contains `"ca."`
- **AND** the word in the subtitle is `"Ca."`
- **THEN** `is_abbrev` SHALL return `true`.
