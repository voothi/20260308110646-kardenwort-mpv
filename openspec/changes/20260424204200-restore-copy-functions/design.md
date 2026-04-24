## Context
The Drum Window (`lls_core.lua`) currently provides a verbatim copy experience designed for multi-line and substring extraction. While this is precise, it bypasses the global `COPY_CONTEXT` and `COPY_MODE` settings that users rely on for generating learning materials. Additionally, because the Drum Window uses "forced" key bindings for navigation, it can sometimes swallow or interfere with global keys like `z` and `x` if they are not explicitly registered in the active keymap.

## Goals / Non-Goals
**Goals:**
- Explicitly bind `z` and `x` in the Drum Window via `manage_dw_bindings`.
- Update `cmd_dw_copy` to support `COPY_CONTEXT` wrapping.
- Update `cmd_dw_copy` to support `COPY_MODE` (Source/Target language) for single-line fallbacks.
- Maintain the verbatim nature of *range selections* while still allowing context wrapping around them.

**Non-Goals:**
- Modifying the core rendering of the Drum Window.
- Adding new UI elements or buttons.

## Decisions

### 1. Explicit Key Registration
We will add `Options.key_cycle_copy_mode` and `Options.key_toggle_copy_context` (or their default string values if not in Options) to the `keys` table in `manage_dw_bindings`. This ensures that even in Book Mode, these keys are processed by the script and show the appropriate OSD feedback.

### 2. Context Extraction Refactoring
We will refactor `get_copy_context_text` to accept an optional `line_idx` parameter. If provided, it will generate context relative to that line instead of the current `time-pos`. This is critical for Book Mode where the user may be looking at a line far from the player's current position.

### 3. Logic-Gated Copy Pipeline
In `cmd_dw_copy`:
- If `FSM.COPY_CONTEXT == "ON"`, the extracted `final_text` (whether a range or single word) will be passed through a context-wrapping filter.
- For single-line fallbacks (no selection range), the script will check `FSM.COPY_MODE`. If mode is "B" (Russian), it will attempt to extract the text from `Tracks.sec.subs` at the same index, provided the tracks are synchronized.

## Risks / Trade-offs
- **Track Sync Desync**: If primary and secondary tracks have different line counts or offsets, `COPY_MODE B` in the Drum Window might copy the wrong line. However, this is an existing limitation of the `lls` dual-subtitle logic.
- **Context Bloat**: Including context for range selections might result in very large clipboard entries. We will adhere to `Options.copy_context_lines` to keep this manageable.
