## 1. Implementation in Scripts

- [x] 1.1 Update `Options.sec_pos_bottom` to `75` in `scripts/lls_core.lua` to provide better default clearance.
- [x] 1.2 Remove the `if is_drum and sec_pos > 50 then` block in `tick_drum` that overrides `sec_pos`.

## 2. Verification

- [x] 2.1 Verify that pressing `r`/`t` and `Shift+r`/`Shift+t` now moves the subtitles as expected in Drum Mode.
- [x] 2.2 Verify that toggling `y` (Secondary Sub Pos) sets the secondary track to its new, separate default bottom position.
