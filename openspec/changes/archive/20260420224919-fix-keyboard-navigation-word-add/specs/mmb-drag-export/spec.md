## MODIFIED Requirements

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
