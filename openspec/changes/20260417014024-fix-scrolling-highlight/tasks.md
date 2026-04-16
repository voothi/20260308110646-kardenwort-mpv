## 1. Core Logic Refactoring

- [ ] 1.1 Update the `draw_drum` function in `scripts/lls_core.lua` to remove the strict `time_pos` range check for the centered subtitle.
- [ ] 1.2 Modify the `active_text` rendering block to pass `is_active = true` to `format_sub` for the `center_idx` line (matching Drum Window logic).

## 2. Verification

- [ ] 2.1 Verify that scrolling with 'a' and 'd' keys in Standard Mode results in an immediate white highlight for the focused subtitle.
- [ ] 2.2 Verify that Drum Mode (C) correctly highlights the middle line in white, even when seeking to the start of a subtitle or navigating through gaps.
- [ ] 2.3 Confirm that context lines (previous/next) in Drum Mode (C) still correctly use the context (gray) styling.
- [ ] 2.4 Ensure Drum Window (W) behavior remains consistent and unaffected.
