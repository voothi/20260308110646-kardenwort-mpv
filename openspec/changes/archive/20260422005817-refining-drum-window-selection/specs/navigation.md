## ADDED Requirements

### Requirement: Line Boundary Selection
The Drum Window must maintain a continuous selection range when moving the cursor between subtitle lines using arrow keys with the Shift modifier.

#### Scenario: Selecting across line break
- **WHEN** the cursor is on the last word of line N and `Shift+RIGHT` is pressed.
- **THEN** the cursor moves to the first word of line N+1, and BOTH the last word of line N and the first word of line N+1 are highlighted in yellow.

### Requirement: Configurable Jump Distances
The jump distances for Ctrl-boosted navigation must be configurable via standard MPV `script-opts`.

#### Scenario: Custom jump words
- **WHEN** `lls-dw_jump_words` is set to 3 in `mpv.conf` and `Ctrl+RIGHT` is pressed.
- **THEN** the cursor jumps forward by 3 words instead of the default 5.
