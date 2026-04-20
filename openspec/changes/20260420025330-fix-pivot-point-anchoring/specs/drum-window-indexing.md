## MODIFIED Requirements

### Requirement: Pivot-Point Anchoring
During context extraction and search, the system SHALL calculate a character-offset "Pivot" based on the user's focus point to eliminate search drift.

- **Pivot Calculation (Refined)**: For single-click/range/set exports, the pivot SHALL be the **exact midpoint character index of the first logical word of the focus point** within the cleaned (tag-free, metadata-free, space-normalized) context block.
- **Pivot Search Scope**: The system SHALL identify all candidate occurrences of the selected term and select the one whose geometric center in the cleaned context string has the smallest absolute distance to the calculated Pivot.

#### Scenario: Resolving Duplicate Common Words
- **GIVEN** a context block: `[Sub 1] Ich mag die Sonne. [Sub 2] Aber die Wolken kommen.`
- **WHEN** the user selects the second `die` (Sub 2).
- **THEN** the system SHALL calculate a pivot position that points specifically to the offset of the word `die` in Sub 2.
- **AND** the engine SHALL extract the context starting from "Aber..." rather than "Ich mag...".

#### Scenario: Multi-word Set Selection
- **GIVEN** a user selects non-contiguous words `A` and `C` from a segment `[A B C]`.
- **WHEN** exporting the set `A ... C`.
- **THEN** the pivot point SHALL be anchored to the midpoint of word `A`.
