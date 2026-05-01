## 1. Cleanup and Refactoring

- [x] 1.1 Remove orphaned `FSM.DW_HIT_ZONES` caching and restoration logic from `draw_dw` (lines 3255-3257 and 3366-3371).
- [x] 1.2 Verify `DRUM_DRAW_CACHE` sentinel logic matches the pattern of `DW_DRAW_CACHE`.

## 2. Cache Invalidation Hardening

- [x] 2.1 Add `is_drum` sentinel to `DRUM_DRAW_CACHE` to track mode transitions.
- [x] 2.2 Integrate `flush_rendering_caches()` into `cmd_toggle_drum` to ensure immediate UI feedback.
- [x] 2.3 Integrate `flush_rendering_caches()` into `cmd_toggle_anki_global` to clear stale highlight caches.
- [x] 2.4 Register an observer for `script-opts` to call `flush_rendering_caches()` upon runtime configuration changes.

## 3. Interaction & Validation

- [x] 3.1 Verify that the 50ms Interaction Shield (`DW_MOUSE_LOCK_UNTIL`) is correctly applied across all interactive layers.
- [x] 3.2 Test that toggling Drum mode while paused on a subtitle immediately updates the OSD style.
- [x] 3.3 Confirm that modifying `dw_font_size` at runtime triggers a layout re-wrap via `LAYOUT_VERSION` increment.
