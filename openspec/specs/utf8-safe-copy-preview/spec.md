# utf8-safe-copy-preview Specification

## Purpose
TBD - created by archiving change 20260517201554-document-copy-mode-b-and-utf8-copy-preview-fixes. Update Purpose after archive.
## Requirements
### Requirement: UTF-8 Safe Copy Preview Truncation
The system SHALL truncate copy preview strings by character boundaries rather than byte boundaries.

#### Scenario: Multibyte Cyrillic boundary
- **WHEN** preview text contains multibyte UTF-8 characters and exceeds the configured preview length
- **THEN** truncation MUST preserve valid UTF-8 characters and MUST append `...` without mojibake artifacts

#### Scenario: Preview builder consistency
- **WHEN** copy preview is emitted for DW or Context copy labels
- **THEN** preview formatting MUST use a single shared builder to produce `"<Label> Copied: <truncated text>"`

