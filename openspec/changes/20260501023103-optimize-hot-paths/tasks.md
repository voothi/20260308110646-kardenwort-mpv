## 1. Hoist `utf8_to_lower` Case-Mapping Tables

- [ ] 1.1 At module scope (after the `utf8_to_table` function definition near L882), add two constants: `local CYRILLIC_UPPER = utf8_to_table("АБВГДЕЁЖЗИЙКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯÄÖÜẞ")` and `local CYRILLIC_LOWER = utf8_to_table("абвгдеёжзийклмнопрстуфхцчшщъыьэюяäöüß")`. These are the exact same strings currently inside `utf8_to_lower()` at L887-888.
- [ ] 1.2 Modify `utf8_to_lower()` (L885-895) to remove the local `upper`, `lower`, `u_table`, `l_table` variables and replace them with references to `CYRILLIC_UPPER` and `CYRILLIC_LOWER`. The `for` loop body stays the same: `res = res:gsub(CYRILLIC_UPPER[i], CYRILLIC_LOWER[i])`.

## 2. Add Drum Mode Draw Cache

- [ ] 2.1 Near L2806 (before `draw_drum`), declare a cache table: `local DRUM_DRAW_CACHE = { center_idx = -1, highlight_count = 0, al = -1, aw = -1, cl = -1, cw = -1, pending_version = 0, result = "" }`. This mirrors the structure of `DW_DRAW_CACHE` at L3052-3057.
- [ ] 2.2 At the top of `draw_drum()` (after the `if center_idx == -1` guard at L2807), add a cache check: if `DRUM_DRAW_CACHE.center_idx == center_idx` AND `DRUM_DRAW_CACHE.highlight_count == #FSM.ANKI_HIGHLIGHTS` AND `DRUM_DRAW_CACHE.al == FSM.DW_ANCHOR_LINE` AND `DRUM_DRAW_CACHE.aw == FSM.DW_ANCHOR_WORD` AND `DRUM_DRAW_CACHE.cl == FSM.DW_CURSOR_LINE` AND `DRUM_DRAW_CACHE.cw == FSM.DW_CURSOR_WORD` AND `DRUM_DRAW_CACHE.pending_version == (FSM.DW_CTRL_PENDING_VERSION or 0)`, then `return DRUM_DRAW_CACHE.result`.
- [ ] 2.3 At the end of `draw_drum()` (just before the `return ass` at L2949), update the cache: set all key fields from the current state and set `DRUM_DRAW_CACHE.result = ass`.

## 3. Build Time-Sorted Highlight Index

- [ ] 3.1 In `load_anki_tsv()`, after the line `FSM.ANKI_HIGHLIGHTS = new_highlights` (L2301), add a block that builds `FSM.ANKI_HIGHLIGHTS_SORTED`. Create an array of `{time = data.time, idx = i}` for each entry, then sort it by `.time` ascending using `table.sort`.
- [ ] 3.2 In `save_anki_tsv_row()`, after the line `table.insert(FSM.ANKI_HIGHLIGHTS, ...)` (L2403), insert the new entry into `FSM.ANKI_HIGHLIGHTS_SORTED` at the correct sorted position. Use a linear scan from the end (since new highlights are typically at the current playback time, which is near the end of the sorted order) to find the insertion point, then use `table.insert(sorted, position, entry)`.
- [ ] 3.3 In `calculate_highlight_stack()`, replace the main loop `for _, data in ipairs(FSM.ANKI_HIGHLIGHTS) do` (L1454) with a conditional: if `Options.anki_global_highlight` is true, keep the existing linear scan unchanged. Otherwise, use binary search on `FSM.ANKI_HIGHLIGHTS_SORTED` to find the start index where `time >= sub_start - window_max`, then iterate only entries with `time <= sub_end + window_max`, looking up the actual data via `FSM.ANKI_HIGHLIGHTS[entry.idx]`. The `window_max` value is `Options.anki_local_fuzzy_window` (plus the multi-word extension if applicable).

## 4. Clear Stale Split-Match Caches on TSV Reload

- [ ] 4.1 In `load_anki_tsv()`, after `FSM.ANKI_HIGHLIGHTS = new_highlights` (L2301) and after building the sorted index (task 3.1), add a loop: `for _, sub in ipairs(Tracks.pri.subs) do sub.__split_valid_indices = nil end` and the same for `Tracks.sec.subs`. Guard with `if Tracks.pri.subs then ... end` and `if Tracks.sec.subs then ... end`.
