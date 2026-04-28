## MODIFIED Requirements

### Requirement: Elliptical Paired Selection
**Delta**: Align with the strictly space-padded ellipsis requirement from the Smart Joiner Service.
- **Joiner**: MUST use the ` ... ` separator for all non-contiguous member joins in the `source_word` field.

#### Scenario: Split selection with contractions
- **WHEN** a user selection contains "she's" and "putting" with a gap
- **THEN** the `source_word` field MUST be "she's ... putting" (preserving the contraction without stripping the ellipsis padding).
