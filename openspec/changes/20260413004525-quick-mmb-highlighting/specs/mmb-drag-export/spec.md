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

### Requirement: Single-Click Selection Commitment (SCM)
A single click of the MMB over an existing multi-word selection SHALL export the entire selection rather than clearing it.

#### Scenario: Committing an existing LMB selection
- **WHEN** there is an active selection (red) in the Drum Window
- **AND** the user clicks MMB within that selection range
- **THEN** the entire existing selection SHALL be exported (turns green and saves to Anki)

### Requirement: Single-Word MMB Export Consistency
A single click of the MMB over non-selected text SHALL export the word under focus.

#### Scenario: Single-click export
- **WHEN** the user clicks (press and release without dragging) MMB on a word that is not part of a selection
- **THEN** only that single word SHALL be exported
