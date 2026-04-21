## Context

The Drum Window (DW) in Kardenwort-mpv relies on a hybrid indexing system (integers for words, fractions for punctuation). While mouse interactions correctly set an "anchor" (`al`/`aw`) and "cursor" (`cl`/`cw`), keyboard navigation only updates the "cursor." The Anki export function `dw_anki_export_selection` contains a fallback path for keyboard focus that is currently incomplete and references an undefined variable `target_sub`, causing script crashes. Additionally, line-based navigation resets the word cursor to a naive index (1), which can fail for lines with leading non-word tokens.

## Goals / Non-Goals

**Goals:**
- Fix the `nil` reference error in the keyboard export path.
- Standardize the synchronization of keyboard cursors to valid logical word tokens.
- Ensure visual feedback (OSD) is consistent across all interaction triggers.

**Non-Goals:**
- Redesigning the underlying Lua State Machine (FSM).
- Modifying the ASS rendering engine or window layouts.

## Decisions

- **Decision: Local definition of `target_sub`**: In the `elseif cl ~= -1` block of `dw_anki_export_selection`, explicitly define `local target_sub = subs[cl]`.
  - *Rationale*: This is the missing link causing the script to crash during keyboard-driven exports.
- **Decision: Intelligent Word Synchronization via Helper**: Implement `get_first_valid_word_idx(sub)` to scan for the first token with `is_word = true`.
  - *Rationale*: This ensures `FSM.DW_CURSOR_WORD` always points to a valid logical index that exists in the rendering/toggle logic, even if the line starts with metadata or punctuation.
- **Decision: Hardened Keyboard Navigation in `cmd_dw_line_move`**: 
  - If not shifting, set `DW_CURSOR_WORD` using the helper and clear the anchor.
  - If shifting, use the helper only if the current cursor word is `-1`.
  - *Rationale*: Maintains selection integrity during range expansion while ensuring a valid starting point for new line moves.

## Risks / Trade-offs

- [Risk] → **Selection Ghosting**: Forcing a word selection on every line move might be unexpected if the line has no word tokens.
- [Mitigation] → If a line conversion results in 0 words, set the cursor index to `-1` to represent a line-only focus state.
- [Risk] → **Performance Overhead**: Frequent OSD updates on navigation.
- [Mitigation] → Reuse existing throttling in the rendering engine; OSD updates in Lua-mpv are non-blocking.
