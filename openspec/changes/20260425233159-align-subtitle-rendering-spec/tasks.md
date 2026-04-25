## 1. Bug Fix Implementation (Completed)

- [x] 1.1 Update `master_tick` in `lls_core.lua` to use `pri_use_osd` and `sec_use_osd`.
- [x] 1.2 Refactor `tick_drum` signature to accept track-specific OSD flags.
- [x] 1.3 Exempt ASS/SSA tracks from OSD rendering to preserve styling.

## 2. Specification Update

- [x] 2.1 Update `openspec/specs/subtitle-rendering/spec.md` with the Track-Aware Suppression requirement.

## 3. Verification & Archiving

- [x] 3.1 Verify resolution of regression `20260425224611` (ASS subtitles display correctly).
- [x] 3.2 Confirm `dw_active` still correctly suppresses all native tracks.
- [ ] 3.3 Archive the change `20260425233159-align-subtitle-rendering-spec`.
