## ADDED Requirements

### Requirement: Elliptical Joiner Support
The smart joiner engine SHALL support the injection of ellipses when reconstructing non-contiguous (split) phrases for display or clipboard export.

#### Scenario: Split Phrase Reconstruction
- **WHEN** a term is flagged as a "split" selection
- **THEN** the system SHALL join the non-contiguous fragments using a standardized ellipsis separator (` ... `).
