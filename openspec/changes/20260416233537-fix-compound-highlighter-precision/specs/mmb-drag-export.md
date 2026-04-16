## ADDED Requirements

### Requirement: Smart Joiner for TSV Composition
TSV export MUST use a smart joiner that preserves the visual spacing of the source text for hyphenated or slashed terms, preventing both space injection and character stripping.

#### Scenario: Exporting Marken-Discount
- **WHEN** Exporting "Marken", "-", and "Discount" together
- **THEN** The resulting term MUST be "Marken-Discount" (no spaces around the dash).
