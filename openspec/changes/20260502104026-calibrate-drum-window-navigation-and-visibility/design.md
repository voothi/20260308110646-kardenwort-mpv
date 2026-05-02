# Design: Calibrate Drum Window Navigation and Visibility

## Context
The Drum Window (DW) serves as the primary interactive hub for language acquisition within Kardenwort-mpv. Recent refinements to achieve "Premium" aesthetic parity (surgical highlighting) introduced a visibility regression where the navigation cursor became invisible on punctuation tokens. Furthermore, horizontal navigation lacks viewport synchronization, leading to a disconnected user experience when jumping across lines.

## Goals / Non-Goals

**Goals:**
- **Visibility**: Ensure the Gold navigation focus and Pink selection markers are always visible, regardless of token type (words vs. symbols).
- **Navigation**: Synchronize the viewport scroll with horizontal word-level navigation.
- **Architectural Parity**: Maintain character-level precision for `LEFT`/`RIGHT` while preserving word-aware vertical movement.

**Non-Goals:**
- Changing the vertical word-snap logic (this remains word-only as per v1.58.18).
- Modifying the core tokenization engine (this remains the source of truth for `is_word`).

## Decisions

### 1. Tiered Highlighting Visibility (`is_manual` flag)
To preserve the "Surgical" look for automated database matches while fixing manual focus visibility, we introduce a tiered evaluation in `format_highlighted_word`:
- **Automated Matches (Priority 3)**: Continue to use surgical logic (punctuation uncolored) for single words to maintain a professional, minimalist look.
- **Manual User Actions (Priority 1 & 2)**: Override the surgical logic to force full-token coloring. This ensures that when a user moves the cursor or selects a range, the feedback is immediate and unambiguous, even on single characters or punctuation.

### 2. Viewport Tracking for Horizontal Jumps
The `cmd_dw_word_move` function will be updated to call `dw_ensure_visible(FSM.DW_CURSOR_LINE, false)`. This ensures that when the cursor jumps to a new line (via the start or end of a horizontal row), the Drum Window automatically scrolls to bring the target line into the visible viewport.

### 3. Preservation of Character-Level Horizontal Precision
Despite the word-only vertical snap, `LEFT`/`RIGHT` will continue to iterate through ALL logical tokens (including symbols). This decision supports the user's requirement for "surgical selection" of punctuation, as defined in the navigation specification (Line 57).

## Risks / Trade-offs

- **Visual Density**: Coloring punctuation for manual focus might slightly increase visual noise during rapid navigation, but this is a necessary trade-off for functional clarity.
- **Performance**: The additional conditional logic in the rendering loop is O(1) and will not impact the O(N) rendering performance of the Drum Window.
