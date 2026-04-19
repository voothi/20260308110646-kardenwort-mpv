## MODIFIED Requirements

### Requirement: Unified Mining Interaction Model
The Drum Window SHALL implement a unified mining interaction model where a single "Smart Add" action automatically distinguishes between contiguous selections and paired set commits based on the word context.

#### Scenario: Smart Commit of Paired Words
- **WHEN** the user interacts with a word that is part of a pending paired set (Pink) using a "Smart Add" trigger (configured in `dw_key_add`)
- **THEN** the system SHALL commit the entire paired set to the TSV immediately.
- **AND** this SHALL NOT require manual modifier keys (e.g., Ctrl).

#### Scenario: Contextual Fallback to Contiguous Export
- **WHEN** the user interacts with a word NOT in a paired set using the same trigger
- **THEN** the system SHALL proceed with standard contiguous export logic.
