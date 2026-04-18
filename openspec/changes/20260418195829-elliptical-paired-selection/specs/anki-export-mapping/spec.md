## ADDED Requirements

### Requirement: Adaptive Contiguity Detection
The export system SHALL detect if a multi-word selection is non-contiguous in the source subtitle and adjust the saved term accordingly.

#### Scenario: Contiguous selection save
- **WHEN** a user selection contains words with sequential `logical_idx` values (e.g. 1, 2, 3).
- **THEN** the system SHALL join them with a single space (e.g. "word1 word2 word3") for the `source_word` field.

#### Scenario: Split selection save
- **WHEN** a user selection contains words with a gap in their `logical_idx` values (e.g. 1, 4).
- **THEN** the system SHALL join them using a space-padded ellipsis (exact string: ` ... `) for the `source_word` field (e.g. "word1 ... word4").

#### Scenario: Multi-Word Fragment Save
- **WHEN** a user selects a single word, skips several, and then selects two adjacent words.
- **THEN** the system SHALL detect the gap after the first word and inject ` ... `, but join the adjacent pair with a space.
- **RESULT**: `Word1 ... Word2 Word3`

#### Scenario: Triple-Split Save
- **WHEN** a user selects three words with gaps between each.
- **THEN** the system SHALL inject ellipses at every gap.
- **RESULT**: `Word1 ... Word2 ... Word3`

### Highlighting Example (Concrete Case)
- **Source Text**: `Entscheiden Sie beim Hören, ob die Aussagen 41 bis 45 richtig oder falsch sind.`
- **Saved Term (1+2 Split)**: `Aussagen ... richtig oder`
  - **Result**: `Aussagen` (Purple), `richtig` (Purple), `oder` (Purple).
- **Saved Term (3-Way Split)**: `Entscheiden ... beim ... ob`
  - **Result**: `Entscheiden` (Purple), `beim` (Purple), `ob` (Purple).
