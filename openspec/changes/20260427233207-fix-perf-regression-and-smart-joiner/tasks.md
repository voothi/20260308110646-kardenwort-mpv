## 1. get_center_index Optimization
- [x] 1.1 Locate both definitions of `get_center_index` in `scripts/lls_core.lua` (around L249 and L888).
- [x] 1.2 Remove the local linear-scan definition (around L888).
- [x] 1.3 Modify the global binary-search definition (L249) to include precision grounding: if `time_pos` falls in a gap between the best match and its adjacent subtitles, return the index of the subtitle with the closest temporal boundary.

## 2. Smart Joiner TSV Export Integration
- [x] 2.1 Locate `dw_anki_export_selection` in `scripts/lls_core.lua`.
- [x] 2.2 Identify the term string building loop. Instead of `table.concat(parts, " ")`, extract the raw text parts into a list.
- [x] 2.3 Pass this list to `compose_term_smart` to assemble the final `term` string before calling `save_anki_tsv_row`.
- [x] 2.4 Locate `ctrl_commit_set` in `scripts/lls_core.lua`.
- [x] 2.5 Replace manual interstitial space addition (`term = term .. " " .. clean_w`) with a clean token array pass to `compose_term_smart`. (Retain `" ... "` logic for explicit gaps).

## 3. Verification
- [x] 3.1 Verify that CPU usage remains low during standard playback (indicating $O(\log N)$ centering).
- [x] 3.2 Verify that pausing the video slightly before a subtitle correctly highlights the upcoming subtitle.
- [x] 3.3 Verify that exporting "Marken-Discount" or similar punctuated phrases yields the correct unspaced string in the TSV file.
