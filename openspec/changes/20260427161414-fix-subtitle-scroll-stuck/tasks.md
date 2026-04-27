## 1. Subtitle Loading Logic

- [ ] 1.1 **Restrict Merging Window**: Update `load_sub` in `scripts/lls_core.lua` to only check the last element (`subs[#subs]`) for potential merges, replacing the current 10-line lookback.
- [ ] 1.2 **Implement Temporal Guard**: Add a condition to the merge logic to only combine identical lines if the gap is <= 0.2s.
- [ ] 1.3 **Add SRT Sorting**: Ensure the `subs` table is sorted by `start_time` after SRT parsing is complete.

## 2. Verification

- [ ] 2.1 **Navigation Test**: Load a video with the reported subtitle sequence and verify that pressing 'd' on "and fifteen" correctly seeks to the following segment.
- [ ] 2.2 **Generic Tag Integrity**: Verify that separate occurrences of `[Music]` or similar tags are preserved as independent seek targets when separated by other subtitles or time gaps.
