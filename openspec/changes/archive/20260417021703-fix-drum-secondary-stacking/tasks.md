## 1. Implementation in Scripts

- [x] 1.1 Update `Options.sec_pos_bottom` to `80` in `scripts/lls_core.lua`.
- [x] 1.2 Remove the old hard override in `tick_drum`.
- [ ] 1.3 Implement "Smart Stacking" in `tick_drum` that respects manual positioning above a safety threshold.
- [ ] 1.4 Swap drawing order in `tick_drum` so Secondary subtitles are drawn on top.

## 2. Verification

- [ ] 2.1 Verify manual `r`/`t` movement is respected.
- [ ] 2.2 Verify that Secondary subtitles stay on top when overlapping.
