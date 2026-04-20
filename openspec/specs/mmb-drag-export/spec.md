# Quick MMB Highlighting (Warm Path)

## Purpose
Enable rapid Anki export by committing contiguous selections upon release of the Middle Mouse Button or via pairing key shortcuts, aligning with the unified "Warm Path" color system.

## Requirements

### Requirement: MMB Hold-to-Select (Gold Path)
The Middle Mouse Button (MMB) in the Drum Window SHALL support hold-and-drag selection behavior for contiguous word ranges.
- **Visual Feedback**: Dragged selections SHALL be rendered in **Gold (#00CCFF)**.
- **Rationale**: Gold signifies the "Warm Path" (Contiguous / Immediate action).

#### Scenario: Dragging selection with Middle Mouse
- **WHEN** the user presses and holds MMB and drags across multiple words.
- **THEN** a Gold highlight SHALL follow the mouse cursor dynamically.

### Requirement: MMB Release-to-Export
Upon release of the MMB, the active selection SHALL be automatically committed to Anki and transitioned to long-term storage highlighting.
- **Saved Colors**:
    - **Orange**: Applied if the selection is contiguous (Standard).
    - **Purple**: Applied if the engine identifies the term as a "Split" phrase (fragmented).

#### Scenario: Auto-export on release
- **WHEN** the user releases MMB after selecting a phrase.
- **THEN** the phrase SHALL be saved to Anki.
- **AND** the highlight SHALL immediately transition from Gold to Orange (or Purple).

### Requirement: Single-Word MMB Export Consistency
A single click of the MMB (no drag) over non-selected text SHALL export the word under focus.

### Requirement: Multi-Occurrence Persistence
Highlights SHALL persist across all textual occurrences of a term, utilizing Multi-Pivot Grounding to ensure exact scene-locking while remaining visible globally if `anki_global_highlight` is active.

### Requirement: Overlap-Based Intensity
The color intensity (depth) of a highlight SHALL only increase if distinct overlapping phrases (e.g., "Aufgaben" and "fünf Aufgaben") are saved for the same word.

### Requirement: Smart Joiner for TSV Composition
TSV export MUST use the smart-joiner-service to preserve the visual spacing of the source text for hyphenated or slashed terms.

#### Scenario: Exporting Marken-Discount
- **WHEN** exporting "Marken", "-", and "Discount".
- **THEN** the resulting term MUST be "Marken-Discount".
