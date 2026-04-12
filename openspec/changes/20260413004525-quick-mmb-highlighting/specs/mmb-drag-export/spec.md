## ADDED Requirements

### Requirement: MMB Hold-to-Select
The Middle Mouse Button (MMB) in the Drum Window SHALL support the same hold-and-drag selection behavior as the Left Mouse Button (LMB).

#### Scenario: Dragging selection with Middle Mouse
- **WHEN** the user presses and holds MMB over a word and drags across multiple lines
- **THEN** a selection (red highlight) SHALL follow the mouse cursor dynamically

### Requirement: MMB Release-to-Export
The Middle Mouse Button (MMB) in the Drum Window SHALL automatically trigger the Anki export process upon release.

#### Scenario: Auto-export on release
- **WHEN** the user releases MMB after selecting a phrase
- **THEN** the phrase SHALL be saved to Anki (green highlight) immediately

### Requirement: Single-Word MMB Export Consistency
A single click of the MMB SHALL export the word under focus.

#### Scenario: Single-click export
- **WHEN** the user clicks (press and release without dragging) MMB on a word
- **THEN** only that single word SHALL be exported
