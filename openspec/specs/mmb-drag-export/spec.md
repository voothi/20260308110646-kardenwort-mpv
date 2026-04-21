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
- **Selection Protection**: If `FSM.DW_PROTECTED_SELECTION` is true, the export engine SHALL ignore subsequent mouse movement during the click and use the pre-existing anchor and cursor boundaries for the commitment.

#### Scenario: Auto-export on release
- **WHEN** the user releases MMB after selecting a phrase.
- **THEN** the phrase SHALL be saved to Anki.
- **AND** the highlight SHALL immediately transition from Gold to Orange (or Purple).

#### Scenario: Preserving Selection on Click
- **WHEN** a multi-word selection is already active.
- **AND** the user clicks MMB *inside* that selection.
- **THEN** the system SHALL enter the "Protected Selection" state.
- **AND** upon release, the entire original selection SHALL be exported, preventing it from collapsing to a single word.

### Requirement: Single-Word MMB Export Consistency
A single click of the MMB (no drag) over non-selected text, OR a keyboard-triggered export (e.g., 'r' key) without an active range selection, SHALL export the token under focus.
- **Fallback Logic**: If `FSM.DW_ANCHOR_LINE` is `-1`, the system SHALL use `FSM.DW_CURSOR_LINE` and `FSM.DW_CURSOR_WORD` as the export point.
- **State Integrity**: The system MUST verify that the target subtitle segment exists and that `FSM.DW_CURSOR_WORD` is valid before initiating an export.

#### Scenario: Keyboard export of a single word
- **WHEN** the user moves the cursor to a word using arrow keys and presses the 'r' key.
- **THEN** the logical word under the cursor SHALL be exported to Anki.
- **AND** the system SHALL provide visual confirmation via OSD.

### Requirement: Multi-Occurrence Persistence
Highlights SHALL persist across all textual occurrences of a term, utilizing Multi-Pivot Grounding to ensure exact scene-locking while remaining visible globally if `anki_global_highlight` is active.

#### Scenario: Visualizing global highlights
- **WHEN** the word "the" is exported as a favorite highlight.
- **AND** `anki_global_highlight` is enabled.
- **THEN** every instance of "the" throughout the media SHALL be highlighted.

### Requirement: Overlap-Based Intensity
The color intensity (depth) of a highlight SHALL only increase if distinct overlapping phrases (e.g., "Aufgaben" and "fünf Aufgaben") are saved for the same word.

#### Scenario: Darkening a mixed highlight
- **WHEN** a word is member to two separate mining records.
- **THEN** the rendering system SHALL apply a "depth 2" color to that specific word.

### Requirement: Smart Joiner for TSV Composition
TSV export MUST use the smart-joiner-service to preserve the visual spacing of the source text for hyphenated or slashed terms.

#### Scenario: Exporting Marken-Discount
- **WHEN** exporting "Marken", "-", and "Discount".
- **THEN** the resulting term MUST be "Marken-Discount".

