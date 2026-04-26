## 1. Loader Improvements

- [x] 1.1 Remove `not has_cyrillic` filter from ASS loader in `load_sub`.
- [x] 1.2 Implement 10-entry lookback merging logic for SRT tracks in `load_sub`.

## 2. Copy Command Refactoring

- [x] 2.1 Reorder `cmd_copy_sub` logic to prioritize internal index over native properties.
- [x] 2.2 Fix fallback logic in `cmd_copy_sub` to correctly select `lines[1]` for Mode A and `lines[#lines]` for Mode B.

## 3. Verification

- [x] 3.1 Verify Russian track support for ASS files in Mode B.
- [x] 3.2 Verify interleaved karaoke merging in SRT files.
- [x] 3.3 Verify OSD-independent copy behavior.
