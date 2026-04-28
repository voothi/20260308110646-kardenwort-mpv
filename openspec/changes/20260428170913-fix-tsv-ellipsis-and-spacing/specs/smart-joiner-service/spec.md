## MODIFIED Requirements

### Requirement: Unified Punctuation Spacing Rule (UPSR)
**Delta**: Enforce strict single-space normalization between words (Anchor: 20260428171824).
- **Single Space Normalization**: The system SHALL NOT insert multiple spaces between words. All tokens consisting solely of whitespace MUST be collapsed to a single space.
- **Whitespace Awareness**: The system SHALL NOT insert an additional space if either the preceding token ends with whitespace or the following token starts with whitespace.

#### Scenario: Joining with multiple source spaces
- **WHEN** joining "find", "   ", and "those"
- **THEN** the result SHALL be "find those" (all intermediate whitespace collapsed to a single space)

### Requirement: Elliptical Joiner Support
**Delta**: Strictly define the space-padded delimiter and ensure it is not stripped by punctuation rules (Anchor: 20260428165923).
- **Separator**: ` ... ` (must include exactly one space on each side of the three dots).
- **Control**: The joiner SHALL NOT strip the padding around the ellipsis, regardless of standard punctuation rules for dots.

#### Scenario: Joining non-contiguous terms
- **WHEN** joining "she's" and "putting" with an elliptical gap
- **THEN** the result SHALL be "she's ... putting"
