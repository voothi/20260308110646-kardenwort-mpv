## 1. Implement Sliding Window in Drum Window (Mode W)

- [x] 1.1 Update `dw_build_layout` in `scripts/lls_core.lua` to calculate `start_idx` and `end_idx` with boundary compensation.
- [x] 1.2 Ensure the window shifts forward when `start_idx < 1` to fill the requested number of `dw_lines_visible`.
- [x] 1.3 Ensure the window shifts backward when `end_idx > #subs` to fill the requested number of `dw_lines_visible`.

## 2. Implement Sliding Window in Drum Mode (Mode C)

- [x] 2.1 Update `draw_drum` in `scripts/lls_core.lua` to calculate `start_idx` and `end_idx` with boundary compensation.
- [x] 2.2 Shift indices as needed to maintain `2 * Options.drum_context_lines + 1` total lines whenever possible.

## 3. Verification

- [x] 3.1 Verify Mode W mouse wheel scrolling: reaching the end of the track should no longer shrink the visible subtitle range.
- [x] 3.2 Verify Mode W 'd' key navigation: seeking to the last subtitle should show a full context window.
- [x] 3.3 Verify Mode C behaves identically at track boundaries.
