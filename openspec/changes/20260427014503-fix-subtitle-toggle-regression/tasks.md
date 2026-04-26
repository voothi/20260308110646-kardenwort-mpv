## 1. Core Logic Refinement

- [x] 1.1 Update `master_tick` in `scripts/lls_core.lua` to incorporate `FSM.native_sub_vis` and `FSM.native_sec_sub_vis` into `pri_use_osd` and `sec_use_osd` flags.
- [x] 1.2 Verify that `cmd_toggle_sub_vis` correctly triggers an OSD update to clear text immediately when toggled OFF.

## 2. Specification Alignment

- [x] 2.1 Ensure `openspec/specs/subtitle-rendering/spec.md` is updated to remove the "Drum Mode Visibility Master" override behavior.
