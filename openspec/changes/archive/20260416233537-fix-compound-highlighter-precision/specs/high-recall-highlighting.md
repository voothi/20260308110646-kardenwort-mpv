## ADDED Requirements

### Requirement: Symbol-Agnostic Neighbor Matching
The strict context neighbor check MUST look past symbol-only tokens (dashes, slashes, brackets) to determine if a neighboring word is present in the recorded context.

#### Scenario: Highlighting compound words
- **WHEN** Checking neighbor for "Netto" in "Netto/Globus"
- **THEN** The engine MUST skip "/" and use "Globus" as the right-hand neighbor for context validation.

#### Scenario: Highlighting bracketed context
- **WHEN** Checking neighbor for "Große" in "Donau) Große"
- **THEN** The engine MUST recognize "Donau" (even with the bracket) as a valid neighbor.
