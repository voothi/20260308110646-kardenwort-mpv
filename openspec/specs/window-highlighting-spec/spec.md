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

### Requirement: Three-Phase Match Evaluation
The rendering engine SHALL evaluate every word against the database using a tiered integrity model to determine the correct highlight palette.

#### Phase 1: Contiguous Adjacency (Orange)
- **Condition**: Both Sequential Adjacency (exact word sequence) AND Contextual Grounding (Multi-Pivot/Neighborhood) are satisfied.
- **Visual**: **Orange (#FF8800)**.
- **Goal**: Highlight "Perfect" matches that exist exactly as saved.

#### Phase 2: Local Fuzzy Match (Green)
- **Condition**: Contextually grounded but fails Sequential Adjacency; term exists as a single word or partial sequence on the current line.
- **Visual**: **Green (#00FF00)**.
- **Goal**: Highlight single-word cards or slightly modified phrase matches on the origin line.

#### Phase 3: Global Split Match (Purple)
- **Condition**: Contextually grounded via high-recall neighborhoods in Global mode, but words are fragmented across segments or non-adjacent.
- **Visual**: **Purple (#AA88FF)**.
- **Goal**: Highlight "Cool Path" pair-selected phrases or high-recall vocabulary.

### Requirement: Match Integrity Conjunction
The rendering engine SHALL NOT assign the Orange (Contiguous) palette to any word unless BOTH sequential adjacency and contextual grounding are met.
- **Fall-back**: If a term is contextually grounded but lacks sequential adjacency, the engine MUST proceed to Phase 3 evaluation.

### Highlighting Example (Concrete Case Refinement)
- **Database Term**: `Aussagen ... richtig oder`
    - **Match Logic**: Skips Orange/Phase 1. Finds `Aussagen`, `richtig`, and `oder` within the 10.0s window. Assigns Purple.
- **Database Term**: `Entscheiden ... beim ... ob`
    - **Match Logic**: Skips Orange/Phase 1. Finds `Entscheiden`, `beim`, and `ob` within the 10.0s window. Assigns Purple.
