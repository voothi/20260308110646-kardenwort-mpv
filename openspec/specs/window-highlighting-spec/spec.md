# Drum Window Highlighting Specification

## Purpose
Define the visual language and rendering priorities for the unified Drum Window, ensuring clear distinction between user actions, automated highlights, and different capture types (contiguous vs. split).

## Requirements

### Requirement: Interaction and Selection Priority
Manual user selections SHALL always carry higher visual priority than automated database highlights.
- **Secondary Priority**: Transient cursor-based hover / focus range. Rendered in **Gold (#00CCFF)**.
- *Terminology Update*: The term "Vibrant Yellow" is deprecated in favor of the standardized **Gold** indicator.

### Requirement: Quick Focus Feedback
#### Scenario: Jump to Segment (Double-Click / Enter)
- **WHEN** the user performs the FIRST click.
- **THEN** the word SHALL momentarily turn **Gold** (Focus Indicator).

### Requirement: MMB Preview Focus
#### Scenario: Export Shortcuts (MMB)
- **WHEN** a user holds MMB on a word.
- **THEN** the word SHALL immediately turn **Gold** (Preview Focus).

### Requirement: Gold Selection (LMB)
#### Scenario: Gold Selection (LMB)
- **WHEN** a user clicks LMB on a word.
- **THEN** it SHALL be highlighted in **Gold** (Current Focus).
- **WHEN** a user clicks and drags LMB.
- **THEN** a contiguous range SHALL be highlighted in **Gold**.
- *Note*: This replaces the legacy "Vibrant Yellow" selection and aligns with the standardized "Warm Path" visuals.

### Requirement: Match Integrity Conjunction
The rendering engine SHALL NOT assign the Orange (Contiguous) palette to any word unless BOTH of the following conditions are met simultaneously:
1.  **Sequential Adjacency**: The word is part of an exact, adjacent word sequence matching the database term within the current line.
2.  **Contextual Grounding**: The match satisfies its Multi-Pivot or neighborhood verification requirements.
- **Fall-back**: If a term is contextually grounded but lacks sequential adjacency, the engine MUST proceed to Phase 3 (Split Match) evaluation to assign the Purple palette.

### Highlighting Example (Concrete Case Refinement)
- **Database Term**: `Aussagen ... richtig oder`
    - **Match Logic**: Skips Orange/Phase 1 (fails Adjacency). Finds `Aussagen`, `richtig`, and `oder` within the 10.0s window.
- **Database Term**: `Entscheiden ... beim ... ob`
    - **Match Logic**: Skips Orange/Phase 1. Finds `Entscheiden`, `beim`, and `ob` within the 10.0s window.
