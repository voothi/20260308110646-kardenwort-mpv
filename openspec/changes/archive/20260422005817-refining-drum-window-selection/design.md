## Context

The Drum Window (`w` mode) provides a scrollable list of subtitles. Users can navigate words and lines using arrow keys. Range selection (yellow highlight) is triggered when holding `Shift`. Currently, the anchor for this selection is not reliably maintained during line transitions, causing visual gaps or resets in the selection trail.

## Goals / Non-Goals

**Goals:**
- Ensure contiguous yellow highlighting across subtitle line boundaries.
- Support both 1-word/line and 5-word/line (Ctrl-boosted) selection.
- Allow users to configure jump distances via `script-opts`.

**Non-Goals:**
- Modifying the "pink" (persistent) selection system.
- Changing mouse-based selection logic.

## Decisions

- **State Capture**: Capture the `FSM.DW_CURSOR_LINE/WORD` into the anchor *before* updating the cursor state in `cmd_dw_word_move` and `cmd_dw_line_move`. This ensures the anchor reflects the logical start of the movement.
- **Configurable Distances**: Move the hardcoded `5` value into `Options.dw_jump_words` and `Options.dw_jump_lines` to permit external override via `mpv.conf`.
- **Keyboard Consistency**: Standardize on `Shift` as the universal "selection active" flag for keyboard navigation functions.

## Risks / Trade-offs

- **Parameter Bloat**: Adding more options to `mpv.conf` slightly increases configuration complexity but provides necessary flexibility for different reading speeds.
