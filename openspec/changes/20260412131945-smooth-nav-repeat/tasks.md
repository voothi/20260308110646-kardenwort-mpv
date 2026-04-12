# Tasks: Unified Smooth Subtitle Navigation

## 1. Options & State

- [x] 1.1 Add `seek_hold_delay` and `seek_hold_rate` to the `Options` table in `lls_core.lua`.
- [x] 1.2 Initialize `FSM.SEEK_REPEAT_TIMER = nil` in the `FSM` state table.

## 2. Core Logic Implementation

- [x] 2.1 Implement `cmd_seek_with_repeat(dir, table)` helper function in `lls_core.lua`.
- [x] 2.2 Inside the helper, handle `table.event == "down"` to trigger initial seek and start the repeat timer (delay then periodic).
- [x] 2.3 Inside the helper, handle `table.event == "up"` to kill and clear the active repeat timer.

## 3. Keyboard Binding Updates

- [x] 3.1 Update global `lls-seek_prev` and `lls-seek_next` bindings at the bottom of the file to use `cmd_seek_with_repeat` with `{complex=true}`.
- [x] 3.2 Update `manage_dw_bindings` for `a`, `d`, `ф`, and `в` to use the new repeat wrapper and `{complex=true}`.
- [x] 3.3 Remove the legacy `settings = "repeatable"` logic for these specific keys in the `manage_dw_bindings` loop.

## 4. Verification & Documentation

- [x] 4.1 Verify holding `a` or `d` starts repeat after the configured delay in Normal mode.
- [x] 4.2 Verify holding `a` or `d` works correctly in Drum Mode (`c`).
- [x] 4.3 Verify holding `a` or `d` works correctly in Drum Window (`w`) and doesn't conflict with word-selection.
- [x] 4.4 Update `release-notes.md` to reflect the new feature and version bump.
- [x] 4.5 Update `mpv.conf` with new navigation repeat settings and documentation.
