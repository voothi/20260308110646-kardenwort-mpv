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

#### Scenario: Visual Line Navigation (Internal Traversal)
- **WHEN** the user is on a visual line of a wrapped subtitle.
- **AND** they press DOWN.
- **THEN** if there is a next visual line within the SAME subtitle, the pointer SHALL move to that visual line.
- **AND** it SHALL stay on the same logical subtitle (index) until all visual lines are exhausted.

#### Scenario: Intelligent Vertical Entry (Directional Landing)
- **WHEN** the user is on Subtitle N and presses DOWN to move to Subtitle N+1 (which is multi-line).
- **THEN** the yellow pointer SHALL land on the FIRST visual line of Subtitle N+1.
- **AND** if the user is on Subtitle N and presses UP to move to Subtitle N-1 (which is multi-line).
- **THEN** the yellow pointer SHALL land on the LAST visual line of Subtitle N-1.

#### Scenario: Entry from Null Selection (Post-Esc)
- **WHEN** the Drum Window has no active selection (`DW_CURSOR_WORD = -1`).
- **AND** the user presses DOWN.
- **THEN** the yellow pointer SHALL activate on the FIRST visual line of the current logical line.
- **AND** if the user presses UP, it SHALL activate on the LAST visual line of the current logical line.
- **AND** if the user presses RIGHT, it SHALL highlight the FIRST token of the current line.

#### Scenario: Multi-Mode Highlighting Parity (is_manual)
- **WHEN** a user performs a manual action (Navigation or Selection).
- **THEN** the system MUST pass `is_manual = true` to the word formatter.
- **AND** the formatter SHALL ensure the highlight covers the ENTIRE token (including punctuation).
- **AND** this behavior SHALL be verified in:
    1. **Drum Window (W)**: Primary interactive grid.
    2. **Drum/SRT OSD (C)**: Main video overlay.
    3. **Translation Tooltip (E)**: Contextual translation window.

#### Scenario: Startup Integrity (Recovery)
- **WHEN** the application starts in `drum` or `srt` mode.
- **AND** the user performs the FIRST navigation action before a subtitle has naturally become active.
- **THEN** the system SHALL automatically snap `DW_CURSOR_LINE` to the active playback line or the nearest boundary (1 or #subs) to prevent navigation deadlocks.
- **AND** a diagnostic log `NAV-RECOVERY` SHALL be emitted to the console for verification.

### Requirement: Architectural Integrity and Parity
- **Consistency**: All navigational logic and visual highlighting (e.g., Yellow Pointer, Pink Selection) MUST behave identically across all three rendering layers: **Drum Window (W)**, **Drum OSD (C)**, and **Translation Tooltip (E)**.
- **Unified Layout**: To prevent regressions in wrapped text navigation, ALL components MUST utilize the `ensure_sub_layout` unified engine to determine visual line boundaries and word coordinates.
- **Backlight Persistence**: Manual highlights (is_manual) MUST preserve their full token boundaries (including punctuation) in all viewing modes, bypassing the surgical punctuation logic reserved for automated database matches.
- **Defensive Design**: Core navigation functions SHALL implement safety fallbacks for missing layout data (e.g., on-demand layout building) to ensure zero-crash startup performance in OSD mode.
