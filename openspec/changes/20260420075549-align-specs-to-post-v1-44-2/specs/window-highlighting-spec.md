## MODIFIED Requirements

### Requirement: Interaction and Selection Priority
Manual user selections SHALL always carry higher visual priority than automated database highlights.
- **Secondary Priority**: Transient cursor-based hover / focus range. Rendered in **Gold (#00CCFF)**.
- *Terminology Update*: The term "Vibrant Yellow" is deprecated in favor of the standardized **Gold** indicator.

### Requirement: Quick Focus Feedback
- **Scenario**: Jump to Segment (Double-Click / Enter)
- **WHEN** the user performs the FIRST click.
- **THEN** the word SHALL momentarily turn **Gold** (Focus Indicator).

### Requirement: MMB Preview Focus
- **Scenario**: Export Shortcuts (MMB)
- **WHEN** a user holds MMB on a word.
- **THEN** the word SHALL immediately turn **Gold** (Preview Focus).

### Highlighting Example (Concrete Case Refinement)
- **Database Term**: `Aussagen ... richtig oder`
    - **Match Logic**: Skips Orange/Phase 1. Finds `Aussagen`, `richtig`, and `oder` within the **10.0s window** (expanded from legacy 1.5s/2.0s).
- **Database Term**: `Entscheiden ... beim ... ob`
    - **Match Logic**: Skips Orange/Phase 1. Finds `Entscheiden`, `beim`, and `ob` within the **10.0s window**.
