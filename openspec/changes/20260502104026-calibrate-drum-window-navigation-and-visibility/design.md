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

### 4. Intelligent Vertical Entry (Visual Line Awareness)
To optimize navigation through long, wrapped subtitles, the vertical movement engine (`cmd_dw_line_move`) is now "visual-line-aware":
- **Internal Traversal**: If a subtitle is multi-line, `UP`/`DOWN` will move through the internal visual rows before jumping to the adjacent subtitle.
- **Directional Landing**: To ensure deterministic behavior, entering a long subtitle from **above** (DOWN) always lands the cursor on the **first** visual line, while entering from **below** (UP) lands it on the **last** visual line.
- **Coordination**: This logic is driven by the `vl_filter` parameter in `dw_closest_word_at_x`, ensuring the horizontal cursor position (x) is preserved across vertical jumps where possible.

### 5. Unified Layout Engine (ensure_sub_layout)
To eliminate the "navigation deadlock" where visual lines were only recognized after opening the Drum Window, we implemented an on-demand layout builder:
- **Shared Interface**: `ensure_sub_layout(sub)` provides a single point of truth for tokenization and wrapping.
- **Cache Parity**: It populates the `sub.layout_cache` using a unified field schema (`words`, `vlines`, `logical_to_visual`). 
- **Mode Independence**: This allows SRT and Drum OSD modes to utilize the same "intelligent" navigation logic as the Drum Window without explicit state-switching.

### 6. Robust Clipboard Logic (PowerShell Retry)
To address Windows-specific `ExternalException` errors during `Set-Clipboard` operations (caused by system-level locks from other applications), we implemented a **Retry Loop** with exponential-style backoff (5 attempts with 50ms sleep).

## Risks / Trade-offs

- **Visual Density**: Coloring punctuation for manual focus might slightly increase visual noise during rapid navigation, but this is a necessary trade-off for functional clarity.
- **Refactoring Debt**: The current solution relies on an on-demand cache population. While robust, a future refactor is planned to unify the three main rendering loops (Drum, DW, Tooltip) into a single "Composer" pattern to further reduce logic duplication.
