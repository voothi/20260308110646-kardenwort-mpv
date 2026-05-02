# Drum Window Highlighting Specification

## Purpose
Define the visual language and rendering priorities for the unified Drum Window, ensuring clear distinction between user actions, automated highlights, and different capture types (contiguous vs. split).

## Requirements

### Requirement: Interaction and Selection Priority
Manual user selections SHALL always carry higher visual priority than automated database highlights.
- **Secondary Priority**: Transient cursor-based hover / focus range. Rendered in **Gold (BGR: 00CCFF | RGB: #FFCC00)**.
- **Visual Parity (is_manual)**: Manual user selections (Gold/Pink) SHALL override surgical highlighting rules to ensure visual feedback on all token types, including punctuation.
- *Terminology Update*: The term "Vibrant Yellow" is deprecated in favor of the standardized **Gold (BGR: 00CCFF | RGB: #FFCC00)** indicator.

#### Scenario: Punctuation Focus Visibility
- **WHEN** the navigation focus (Gold) or manual selection (Pink) resides on a punctuation-only token.
- **THEN** the rendering engine SHALL color the entire token, bypassing the "surgical" uncolored-punctuation logic used for automated matches.

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

### Requirement: Two-Phase Match Evaluation
The rendering engine SHALL evaluate every word against the database using a tiered integrity model to determine the correct highlight palette.

#### Phase 1: Contiguous Adjacency (Orange)
- **Condition**: Both Sequential Adjacency (exact word sequence) AND Contextual Grounding (Multi-Pivot/Neighborhood) are satisfied.
- **Visual**: **Orange (BGR: 0088FF | RGB: #FF8800)**.
- **Goal**: Highlight "Perfect" matches that exist exactly as saved.

#### Phase 2: Split Match (Purple)
- **Condition**: Contextually grounded via high-recall neighborhoods, but words are fragmented and lack strict sequence adjancency.
- **Visual**: **Purple (BGR: FF88B0 | RGB: #B088FF)**.
- **Goal**: Highlight "Cool Path" pair-selected phrases or high-recall single vocabulary words scattered in a segment.

### Requirement: Match Integrity Conjunction
The rendering engine SHALL NOT assign the Orange (Contiguous) palette to any word unless BOTH sequential adjacency and contextual grounding are met.
- **Fall-back**: If a term is contextually grounded but lacks sequential adjacency, the engine MUST proceed to Phase 2 (Split) evaluation.

### Highlighting Example (Concrete Case Refinement)
- **Database Term**: `Aussagen ... richtig oder`
    - **Match Logic**: Skips Orange/Phase 1. Finds `Aussagen`, `richtig`, and `oder` within the 10.0s window spanning multiple lines. Assigns Purple.
- **Database Term**: `Entscheiden ... beim ... ob`
    - **Match Logic**: Skips Orange/Phase 1. Finds `Entscheiden`, `beim`, and `ob` within the 10.0s window spanning multiple lines. Assigns Purple.

### Requirement: Opaque Highlight Outlines
All interactive highlights (manual selections) SHALL use opaque border (`\3a&H00&`) and shadow (`\4a&H00&`) alphas to eliminate visual blooming, regardless of the global background transparency setting.

#### Scenario: Rendering yellow selection
- **WHEN** a word is manually selected in any mode (SRT, Drum, DW, Tooltip)
- **THEN** the rendered token SHALL have a sharp black outline with 0% transparency.

### Requirement: Regular Weight for Manual Selections
Manual selection highlights SHALL always be rendered with regular font weight (`{\b0}`) to maintain a "Premium" aesthetic, decoupling them from the bold weight used for database matches.

#### Scenario: Selecting a word in an active line
- **WHEN** a word is selected within a bolded active playback line
- **THEN** the selection highlight SHALL be regular weight, while the rest of the line remains bold.
