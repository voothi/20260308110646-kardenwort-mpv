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

### Requirement: Match Integrity Conjunction
The rendering engine SHALL NOT assign the Orange (Contiguous) palette to any word unless BOTH of the following conditions are met simultaneously:
1.  **Sequential Adjacency**: The word is part of an exact, adjacent word sequence matching the database term within the current line.
2.  **Contextual Grounding**: The match satisfies its Multi-Pivot or neighborhood verification requirements.
- **Fall-back**: If a term is contextually grounded but lacks sequential adjacency, the engine MUST proceed to Phase 3 (Split Match) evaluation to assign the Purple palette.
