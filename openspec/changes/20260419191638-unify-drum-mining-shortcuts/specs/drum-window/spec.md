## MODIFIED Requirements

### Requirement: Unified Mining Interaction Model
The Drum Window SHALL implement a unified mining interaction model where a single "Smart Add" action automatically distinguishes between contiguous selections and paired set commits based on the word context.

#### Scenario: Smart Commit of Paired Words
- **WHEN** the user interacts with a word that is part of a pending Paired Selection Set using a "Smart Add" trigger (configured in `dw_key_add`)
- **THEN** the system SHALL commit the entire paired set to the TSV immediately.
- **AND** this SHALL NOT require manual modifier keys (e.g., Ctrl).

#### Scenario: Contextual Fallback to Contiguous Export
- **WHEN** the user interacts with a word NOT in a paired set using the same trigger
- **THEN** the system SHALL proceed with standard contiguous export logic.

### Requirement: Modal Highlight Stacking Priority
The Drum Window SHALL enforce a strict visual priority for overlapping selections and highlights to ensure clarity during the mining process.

#### Scenario: Paired Selection Precedence
- **WHEN** a word is part of the pending Paired Selection set
- **THEN** it SHALL be rendered in the paired choice color regardless of any active contiguous selection or existing database highlights.
- **PRIORITY**: Paired (Highest) > Active Selection (Medium) > Database Highlights (Lowest).

#### Scenario: Contiguous Selection Precedence over Saved State
- **WHEN** a word is currently being selected using a contiguous trigger
- **AND** it is NOT part of a paired set
- **THEN** its selection color SHALL override its existing database highlight.
- **RESULT**: Active task focus (selecting) is always visually dominant over persistent state (saved).
