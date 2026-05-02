## MODIFIED Requirements

### Requirement: Character-Level Precision (Horizontal)
- **Baseline**: `openspec/specs/drum-window-navigation/spec.md`
- **Refinement**: Horizontal navigation SHALL continue to support character-level precision for all logical tokens, but MUST trigger a viewport follow-check upon line transition.

#### Scenario: Viewport Follow (Horizontal Jump)
- **WHEN** the user navigates LEFT or RIGHT past the horizontal bounds of a line.
- **THEN** the Drum Window SHALL jump to the new line AND immediately call the viewport tracking engine (`dw_ensure_visible`) to follow the cursor.
