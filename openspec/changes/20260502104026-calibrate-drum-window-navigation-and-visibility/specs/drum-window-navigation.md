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
- **AND** if the user navigates LEFT from the first token of a line.
- **THEN** the yellow pointer SHALL jump to the LAST valid token of the previous line.

#### Scenario: Visual Line Navigation (Wrapped Subtitles)
- **WHEN** a single subtitle is wrapped into multiple visual lines.
- **AND** the user navigates UP or DOWN.
- **THEN** the pointer SHALL move to the adjacent visual line within the SAME subtitle first.
- **AND** only if the edge of the subtitle is reached SHALL it jump to the next subtitle.
- **AND** when jumping to a NEW subtitle, it SHALL land on the FIRST visual line (if moving DOWN) or the LAST visual line (if moving UP).

#### Scenario: Entry from Null Selection (Post-Esc)
- **WHEN** the Drum Window has no active selection (`DW_CURSOR_WORD = -1`).
- **AND** the user presses RIGHT.
- **THEN** the yellow pointer SHALL highlight the FIRST valid token of the current line.
- **AND** if the user presses LEFT, it SHALL highlight the LAST valid token of the current line.
- **AND** if the user presses DOWN, it SHALL activate the pointer on the FIRST visual line of the current subtitle.
- **AND** if the user presses UP, it SHALL activate the pointer on the LAST visual line of the current subtitle.

#### Scenario: Startup Recovery (No Initial Selection)
- **WHEN** the script starts AND no subtitle is currently active (e.g., at 00:00).
- **AND** the user presses a navigation key (UP, DOWN, LEFT, RIGHT).
- **THEN** the system SHALL initialize `DW_CURSOR_LINE` to the first subtitle (for DOWN/RIGHT) or last subtitle (for UP/LEFT) and begin navigation.

### Requirement: Architectural Integrity and Parity
- **Consistency**: All navigational logic and visual highlighting (e.g., Yellow Pointer, Pink Selection) MUST behave identically across all three rendering layers: **Drum Window (W)**, **Drum OSD (C)**, and **Translation Tooltip (E)**.
- **Unified Layout**: To prevent regressions in wrapped text navigation, ALL components MUST utilize the `ensure_sub_layout` unified engine to determine visual line boundaries and word coordinates.
- **Backlight Persistence**: Manual highlights (is_manual) MUST preserve their full token boundaries (including punctuation) in all viewing modes, bypassing the surgical punctuation logic reserved for automated database matches.
- **Defensive Design**: Core navigation functions SHALL implement safety fallbacks for missing layout data (e.g., on-demand layout building) to ensure zero-crash startup performance in OSD mode.
