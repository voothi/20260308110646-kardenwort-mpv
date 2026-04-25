## 1. Specification Update

- [ ] 1.1 Update `openspec/specs/subtitle-rendering/spec.md` with the Track-Aware Suppression requirement.

## 2. Implementation Verification

- [ ] 2.1 Confirm `master_tick` (lines 3965+) correctly calculates `pri_use_osd` and `sec_use_osd`.
- [ ] 2.2 Verify that `sub-visibility` and `secondary-sub-visibility` are independently toggled based on track type.
- [ ] 2.3 Ensure the Drum Window (`dw_active`) still forces global suppression.

## 3. Verification & Archiving

- [ ] 3.1 Perform a sanity check with mixed SRT/ASS tracks to ensure ASS styling is preserved.
- [ ] 3.2 Archive the change `20260425233159-align-subtitle-rendering-spec`.
