# Tasks: Calibration Mode (Visual Debug & Self-Adjusting)

## 1. Infrastructure & State

- [x] 1.1 Add `FSM.CALIBRATION_MODE = false` and `calibration_osd` overlay to `lls_core.lua`.
- [x] 1.2 Implement `cmd_toggle_calibration()` and register it to a keybinding (e.g., `Shift+B`).
- [x] 1.3 Add logic to `flush_rendering_caches()` to also clear `calibration_osd`.

## 2. Visual Debug Overlay

- [x] 2.1 Create `render_calibration_overlay()` function that iterates through current `hit_zones`.
- [x] 2.2 Draw semi-transparent magenta boxes for word hit-zones and cyan for line boundaries.
- [x] 2.3 Ensure overlay updates whenever `LAYOUT_VERSION` increments or multipliers change.

## 3. Interactive Tuning

- [x] 3.1 Implement `manage_calibration_bindings(enable)` using `mp.set_key_bindings`.
- [x] 3.2 Implement increment/decrement logic for `dw_char_width`, `dw_line_height_mul`, and `dw_vsp`.
- [x] 3.3 Ensure all adjustments trigger `flush_rendering_caches()` and refresh the OSD.

## 4. Persistence

- [x] 4.1 Implement `cmd_save_calibration()` to append settings to `mpv.conf`.
- [x] 4.2 Use a ZID-timestamped block for traceability in `mpv.conf`.
- [x] 4.3 Bind `Enter` to save and `Esc` to exit in Calibration Mode.

## 5. Verification & Cleanup

- [x] 5.3 Ensure Calibration Mode is disabled upon quitting or loading new media.
