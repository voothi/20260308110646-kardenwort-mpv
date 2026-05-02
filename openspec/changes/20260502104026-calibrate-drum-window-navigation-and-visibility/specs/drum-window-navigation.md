## MODIFIED Requirements

### Requirement: Character-Level Precision (Horizontal)
- **Baseline**: `openspec/specs/drum-window-navigation/spec.md`
- **Refinement**: Horizontal navigation SHALL continue to support character-level precision for all logical tokens, but MUST trigger a viewport follow-check upon line transition.

#### Scenario: Viewport Follow (Horizontal Jump)
- **WHEN** the user navigates LEFT or RIGHT past the horizontal bounds of a line.
- **THEN** the Drum Window SHALL jump to the new line AND immediately call the viewport tracking engine (`dw_ensure_visible`) to follow the cursor.

#### Scenario: Line Wrap Alignment
- **WHEN** the user navigates RIGHT from the last token of a line.
- **THEN** the yellow pointer SHALL jump to the FIRST valid token of the next line.
- **WHEN** the user navigates LEFT from the first token of a line.
- **THEN** the yellow pointer SHALL jump to the LAST valid token of the previous line.

#### Scenario: Entry from Null Selection (Post-Esc)
- **WHEN** the Drum Window has no active selection (`DW_CURSOR_WORD = -1`).
- **AND** the user presses RIGHT.
- **THEN** the yellow pointer SHALL highlight the FIRST valid token of the current line.
- **AND** if the user presses LEFT, it SHALL highlight the LAST valid token of the current line.
