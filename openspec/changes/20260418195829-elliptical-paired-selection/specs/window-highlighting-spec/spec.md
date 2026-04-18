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

#### Scenario: Multi-Part Split Highlighting
- **GIVEN** a term contains multiple ellipses (e.g., `Entscheiden ... beim ... ob`).
- **WHEN** the highlighter evaluates the term.
- **THEN** it SHALL identify all three components (`Entscheiden`, `beim`, `ob`) across the scan radius.
- **AND** it SHALL highlight all involved words in the **Purple** palette.

#### Scenario: Partial Contiguity within Split Terms
- **GIVEN** a term contains mixed contiguity (e.g., `Aussagen ... richtig oder`).
- **WHEN** the highlighter evaluates the term.
- **THEN** it SHALL treat the entire term as Split-Only due to the presence of ` ... `.
- **AND** it SHALL highlight the single word (`Aussagen`) and the contiguous pair (`richtig`, `oder`) together in the purple palette when found in the same context.

### Highlighting Example (Concrete Case)
- **Source Context**: `Entscheiden Sie beim Hören, ob die Aussagen 41 bis 45 richtig oder falsch sind.`
- **Database Term**: `Aussagen ... richtig oder`
  - **Match Logic**: Skips Orange/Phase 1. Finds `Aussagen`, `richtig`, and `oder` within the 2.0s window.
  - **Visual**: `Aussagen` (Purple), `richtig` (Purple), `oder` (Purple).
- **Database Term**: `Entscheiden ... beim ... ob`
  - **Match Logic**: Skips Orange/Phase 1. Finds `Entscheiden`, `beim`, and `ob` within the 2.0s window.
  - **Visual**: `Entscheiden` (Purple), `beim` (Purple), `ob` (Purple).
