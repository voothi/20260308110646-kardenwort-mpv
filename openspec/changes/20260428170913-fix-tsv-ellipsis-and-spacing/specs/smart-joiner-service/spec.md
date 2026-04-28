## MODIFIED Requirements

### Requirement: Unified Punctuation Spacing Rule (UPSR)
**Delta**: Clarify whitespace awareness to prevent doubled spaces.
- **Whitespace Awareness**: The system SHALL NOT insert a space if either the preceding token ends with whitespace or the following token starts with whitespace.

#### Scenario: Joining with existing spaces
- **WHEN** joining "find", "   ", and "those"
- **THEN** the result SHALL be "find   those" (no additional spaces injected)

### Requirement: Elliptical Joiner Support
**Delta**: Strictly define the space-padded delimiter and ensure it is not stripped by punctuation rules.
- **Separator**: ` ... ` (must include exactly one space on each side of the three dots).
- **Control**: The joiner SHALL NOT strip the padding around the ellipsis, regardless of standard punctuation rules for dots.

#### Scenario: Joining non-contiguous terms
- **WHEN** joining "she's" and "putting" with an elliptical gap
- **THEN** the result SHALL be "she's ... putting"
