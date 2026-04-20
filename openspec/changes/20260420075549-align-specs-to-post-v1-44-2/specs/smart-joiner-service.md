## ADDED Requirements

### Requirement: Unified Punctuation Spacing Rule (UPSR)
The smart joiner engine MUST preserve compound word visual formatting and follow standard spacing rules.
- **Rule**: NO space SHALL be inserted before or after symbols: `/`, `-`.
- **Rationle**: Prevents "Marken - Discount" and ensures "Marken-Discount".

### Requirement: Elliptical Joiner Support
The engine SHALL inject space-padded ellipses (` ... `) when joining non-contiguous fragments into a single term.
- **Trigger**: Detected via gaps in logical word indices.

### Requirement: Punctuation Preservation
The service MUST preserve the exact character sequence of internal punctuation (commas, dashes) while only stripping boundaries for dictionary accuracy.
