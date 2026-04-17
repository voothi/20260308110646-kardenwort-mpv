## ADDED Requirements

### Requirement: Drum Window Selection Priority
The system SHALL prioritize the presentation of persistent multi-word selections (Ctrl + LMB) over transient cursor-based highlighting or drag-selection ranges in the Drum Window (Mode W).

#### Scenario: Selection Overlap
- **GIVEN** one or more words are already marked with `dw_ctrl_select_color` (muted yellow)
- **WHEN** the user hovers the mouse over one of these words or includes it in a standard selection range (LMB drag)
- **THEN** THE OSD SHALL continue to display the word using `dw_ctrl_select_color` instead of overriding it with `dw_highlight_color` (vibrant yellow).
