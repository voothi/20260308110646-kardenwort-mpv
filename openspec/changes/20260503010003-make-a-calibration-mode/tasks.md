# Tasks: Calibration Mode (Visual Debug & Self-Adjusting)

## 1. Infrastructure & State

- [ ] 1.1 Add `FSM.CALIBRATION_MODE = false` and `calibration_osd` overlay to `lls_core.lua`.
- [ ] 1.2 Implement `cmd_toggle_calibration()` and register it to a keybinding (e.g., `Shift+B`).
- [ ] 1.3 Add logic to `flush_rendering_caches()` to also clear `calibration_osd`.

## 2. Visual Debug Overlay

- [ ] 2.1 Create `render_calibration_overlay()` function that iterates through current `hit_zones`.
- [ ] 2.2 Draw semi-transparent magenta boxes for each hit-zone using ASS tags.
- [ ] 2.3 Ensure the overlay updates immediately when `FSM.LAYOUT_VERSION` increments.

## 3. Live Tuning Interface

- [ ] 3.1 Implement a keybinding group for calibration (`[`, `]`, `{`, `}`, `Shift+[`, `Shift+]`).
- [ ] 3.2 Add handler functions to increment/decrement `Options.dw_char_width`, `Options.dw_line_height_mul`, and `Options.dw_vsp`.
- [ ] 3.3 Create a "Status HUD" in the overlay showing current multiplier values in real-time.

## 4. Persistence Engine

- [ ] 4.1 Implement `save_calibration_to_config()` that appends current multipliers to `mpv.conf`.
- [ ] 4.2 Add safety check to ensure `mpv.conf` is writable and use the current ZID as a block header.
- [ ] 4.3 Trigger a success OSD notification upon successful save.

## 5. Verification & Cleanup

- [ ] 5.1 Test calibration in both Drum Window and Drum Mode.
- [ ] 5.2 Verify that manual selection accuracy follows the visual boxes.
- [ ] 5.3 Ensure Calibration Mode is disabled upon quitting or loading new media.
