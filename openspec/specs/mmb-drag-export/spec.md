# Quick MMB Highlighting

## Requirements

### Requirement: MMB Hold-to-Select
The Middle Mouse Button (MMB) in the Drum Window SHALL support the same hold-and-drag selection behavior as the Left Mouse Button (LMB).
- **When** the user presses and holds MMB over a word, that word SHALL become the selection anchor.
- **When** the user drags the mouse while holding MMB, the selection SHALL extend to the word currently under the mouse.
- The selection SHALL be visually represented (typically a red background highlight).

### Requirement: MMB Release-to-Export
The Middle Mouse Button (MMB) in the Drum Window SHALL automatically trigger the Anki export process upon release.
- **When** the user releases MMB, the currently selected text (established during the drag or a single click) SHALL be processed for Anki export.
- Transitioning from selection (red) to export result (green highlight) SHALL occur immediately without requiring further clicks.

### Requirement: Selection Priority
The MMB interaction SHALL update the global selection state of the Drum Window, overriding any existing selection from previous mouse actions.

### Requirement: Consistency with Single Click
A single click of the MMB (press and release without significant movement) SHALL continue to export the single word under the cursor.

### Requirement: Non-Interference with Search
The new MMB behavior SHALL NOT interfere with the Middle Click behavior in other modes (like search mode if applicable) or the "SCM" function if defined separately.
