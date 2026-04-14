# Spec: TSV State Recovery

> Capability: `tsv-state-recovery`
> Introduced: `20260414123431-fix-tsv-deletion-crash`

## Requirements

### Requirement: TSV State Recovery
The system SHALL clear `FSM.ANKI_HIGHLIGHTS` whenever the `.tsv` record file cannot be opened, ensuring that highlights from a previous file are not retained in memory after the file is deleted or becomes unreadable. If the file is missing, the system SHALL attempt to create a fresh file with a default header row before returning. The header row of any opened file SHALL be excluded from highlight loading by comparing the term column value against the actual configured field name from `anki_mapping.ini`, not a hardcoded list. The file-reading loop SHALL be wrapped in a `pcall` so that a Lua error on a malformed line does not propagate to the calling observer.

#### Scenario: File deleted while mpv is running
- **WHEN** the `.tsv` record file is deleted from disk during an active mpv session
- **AND** `load_anki_tsv` is invoked (either via the periodic timer or on window open)
- **THEN** `FSM.ANKI_HIGHLIGHTS` SHALL be reset to an empty table
- **AND** the script SHALL attempt to create a new `.tsv` file at the same path with a default header

#### Scenario: File contains only a header row
- **WHEN** the `.tsv` file exists but contains only the header row
- **AND** the term column header value matches the configured field name (e.g. `"Quotation"`)
- **THEN** the header row SHALL be skipped and `FSM.ANKI_HIGHLIGHTS` SHALL be set to an empty table
- **AND** no phantom highlight entry SHALL be created for the header field name

#### Scenario: File is empty (0 bytes)
- **WHEN** the `.tsv` file exists but contains no content
- **THEN** the parse loop SHALL complete immediately with zero entries
- **AND** `FSM.ANKI_HIGHLIGHTS` SHALL be set to an empty table
