## MODIFIED Requirements

### Requirement: Interaction and Selection Priority
- **Baseline**: `openspec/specs/window-highlighting-spec/spec.md`
- **Refinement**: Manual user selections (Gold/Pink) SHALL override surgical highlighting rules to ensure visual feedback on all token types, including punctuation.

#### Scenario: Punctuation Focus Visibility
- **WHEN** the navigation focus (Gold) or manual selection (Pink) resides on a punctuation-only token.
- **THEN** the rendering engine SHALL color the entire token, bypassing the "surgical" uncolored-punctuation logic used for automated matches.
