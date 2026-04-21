## Context

The Drum Window (Mode W) implements its own word-wrapped text layout and hit-testing logic for mouse interaction. Keyboard navigation currently uses a simple line-and-word index system. Vertical movement always resets the word index to the first word of the next line, which is visually jarring and inefficient for editing-like workflows.

## Goals / Non-Goals

**Goals:**
- Implement a "sticky column" (X-coordinate persistence) for vertical navigation.
- Ensure the sticky column is updated correctly during horizontal movement.
- Maintain consistent behavior across wrapped multi-line subtitles.
- Reset sticky state when the cursor is cleared or manually repositioned by mouse.

**Non-Goals:**
- Implementing a full character-level carriage (limited to word-level "words-as-characters" logic).
- Changing the underlying ASS rendering engine constraints.

## Decisions

### 1. Persistent OSD-Space X-Coordinate
- **Decision**: Store a transient `DW_CURSOR_X` in the FSM state.
- **Rationale**: Tracking absolute OSD-space coordinates (0-1920) is more robust than using character indices, as it handles proportional font widths and word-wrapping layout changes between lines.

### 2. Lazy Sentinel Value (nil)
- **Decision**: Use `nil` as the uninitialized state for `DW_CURSOR_X`.
- **Rationale**: `nil` is idiomatic in Lua and allows for an easy "if not X then initialize" pattern. It avoids magic numbers like `-1` and ensures the sticky column is re-anchored to the *actual* word position upon the first movement after a reset.

### 3. Word-Center Snapping
- **Decision**: Calculate the center position of words for alignment checks.
- **Rationale**: Snapping to the center of the word closest to the target X provides the most natural "code editor" feel when moving between lines of different lengths and word densities.

## Risks / Trade-offs

- **[Risk] Layout Mismatch** → **[Mitigation]** Re-use the exact same word-wrap logic from `dw_build_layout` inside the sticky-X calculation helper to ensure parity between rendering and navigation logic.
- **[Risk] Stale State** → **[Mitigation]** Explicitly reset `DW_CURSOR_X = nil` in all state-clearing locations (ESC, mouse seek, track change).
