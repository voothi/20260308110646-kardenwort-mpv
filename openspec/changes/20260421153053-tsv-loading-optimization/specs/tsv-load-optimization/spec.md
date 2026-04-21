## ADDED Requirements

### Requirement: Database Fingerprinting
The system SHALL calculate a unique fingerprint for the TSV database file to detect content changes without reading the full file.
- **Fingerprint Method**: Combination of modification time (`mtime`) and file size.
- **Resolution**: MUST support sub-second modification time if provided by the filesystem.

#### Scenario: Detecting file change
- **WHEN** the TSV file is updated with a new highlight or edited externally
- **THEN** its modification time or size changes, producing a new fingerprint.

### Requirement: Parse-on-Mismatch Optimization
The TSV loading engine SHALL only execute the full parsing and indexing logic if the current file fingerprint differs from the in-memory state.
- **Prerequisite**: If no highlights are present in memory, fingerprint matching MUST be bypassed to ensure initial load.
- **Override**: Manual or forced reloads SHALL have the capability to bypass the fingerprint check.

#### Scenario: Skipping redundant reload
- **WHEN** `load_anki_tsv` is called (e.g. from periodic sync)
- **AND** the file fingerprint matches the last successfully loaded version
- **AND** the in-memory highlight count is greater than zero
- **THEN** the system SHALL skip reading and parsing the file.

#### Scenario: Triggering necessary reload
- **WHEN** the file fingerprint changes (e.g. after a new highlight is saved)
- **THEN** the system SHALL perform a full parse of the TSV and rebuild the highlight index.
