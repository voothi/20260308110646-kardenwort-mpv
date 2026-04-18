## MODIFIED Requirements

### Requirement: Palette Precedence and Priority Logic
The highlighting engine MUST evaluate potential matches in a specific order to ensure that the most natural reading (contiguous phrases) is prioritized. However, it SHALL explicitly ignore terms containing the ellipsis (`...`) marker during the contiguous matching phase.

#### Scenario: Contiguous Priority for Nearby Words
- **GIVEN** a saved term contains multiple words.
- **WHEN** those words appear in a subtitle segment as an exact, adjacent sequence.
- **AND** the saved term does NOT contain the space-padded ellipsis (` ... `).
- **THEN** the engine SHALL render them using the **Orange** palette rather than Purple.
- **AND** this priority applies regardless of how the term was originally selected or saved.

#### Scenario: Elliptical Term Bypass
- **GIVEN** a saved term contains words joined by a space-padded ellipsis (e.g., `Sie ... Hören`).
- **WHEN** the words `Sie` and `hören` appear contiguously in a subtitle.
- **THEN** the engine SHALL NOT highlight them in the Orange palette for this specific term match.
- **BUT** they SHALL still be eligible for Purple palette highlighting as a zero-distance Split Match.

## ADDED Requirements

### Requirement: Split Match Context Anchor
Terms saved with a space-padded ellipsis (` ... `) MUST be strictly evaluated as split-context phrases.

#### Scenario: Enforcing Split Match for Elliptical Terms
- **WHEN** the engine encounters a term with the ` ... ` marker.
- **THEN** it SHALL bypass Phase 1 (Contiguous) and Phase 2 (Contextual) evaluations.
- **AND** it SHALL initiate Phase 3 (Split Match) to identify the component words within the scan cluster.
