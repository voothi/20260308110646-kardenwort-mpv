## ADDED Requirements

### Requirement: Unified Mode Toggles
The keys `z` and `x` must be responsive in all UI states, including the Drum Window and Book Mode.

#### Scenario: Toggling Context Copy in Book Mode
- **WHEN** the Drum Window is open and Book Mode is ON.
- **THEN** pressing `x` must toggle `FSM.COPY_CONTEXT` and display an OSD message "Context Copy: ON/OFF".

#### Scenario: Cycling Copy Mode in Book Mode
- **WHEN** the Drum Window is open and Book Mode is ON.
- **THEN** pressing `z` must cycle `FSM.COPY_MODE` and display the corresponding OSD message.

### Requirement: Contextual Drum Copy
The Drum Window copy command (`Ctrl+C`) must support context-aware extraction when enabled.

#### Scenario: Verbatim Selection with Context
- **WHEN** a range of words is selected in the Drum Window and `COPY_CONTEXT` is "ON".
- **THEN** the clipboard must contain the selected text wrapped with `copy_context_lines` from the surrounding subtitle track.

### Requirement: Language-Aware Fallback
The single-item fallback (word/line) in the Drum Window must respect the selected language target.

#### Scenario: Copying Translation from Drum Window
- **WHEN** the cursor is on a line in the Drum Window, `COPY_MODE` is "B" (Russian), and `Ctrl+C` is pressed.
- **THEN** the clipboard must contain the Russian translation of that specific line instead of the source text.
