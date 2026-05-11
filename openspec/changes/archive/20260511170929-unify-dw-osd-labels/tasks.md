## 1. Simplify Drum Window Status Label

- [x] 1.1 Update `cmd_adjust_sub_pos` in `scripts/lls_core.lua` to show "Drum Window: Active" instead of "Drum Window: Active (Position Locked)".
- [x] 1.2 Update `cmd_adjust_sec_sub_pos` in `scripts/lls_core.lua` to show "Drum Window: Active" instead of "Drum Window: Active (Position Locked)".

## 2. Unify Managed Inscriptions

- [x] 2.1 Add "Managed by Drum Window" check and OSD to `cmd_toggle_sub_vis` in `scripts/lls_core.lua`.
- [x] 2.2 Add "Managed by Drum Window" check and OSD to `cmd_cycle_sec_sid` in `scripts/lls_core.lua`.
- [x] 2.3 Add "Managed by Drum Window" check and OSD to `cmd_cycle_sec_pos` in `scripts/lls_core.lua`.
- [x] 2.4 Add "Managed by Drum Window" check and OSD to `cmd_toggle_karaoke` in `scripts/lls_core.lua`.

## 3. Verification

- [x] 3.1 Verify `x` key still shows "Managed by Drum Window" in DW mode.
- [x] 3.2 Verify `Shift+x`, `c`, `Shift+c`, `Shift+f` show "Managed by Drum Window" in DW mode.
- [x] 3.3 Verify positioning keys (`r`, `t`, `R`, `T`) show simplified "Drum Window: Active" in DW mode.
