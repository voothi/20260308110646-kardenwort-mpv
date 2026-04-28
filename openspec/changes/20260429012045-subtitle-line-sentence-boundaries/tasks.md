## 1. NUL Sanitization in Subtitle Loader

- [ ] 1.1 In `load_sub` (SRT branch, inside the `TEXT` state block), strip any `\0` characters from each line before assigning to `current_sub.text`
- [ ] 1.2 In `load_sub` (ASS branch, after extracting `raw_text`), strip any `\0` characters from `raw_text` before storing

## 2. Switch Context Join Separator to NUL Sentinel

- [ ] 2.1 In `dw_anki_export_selection`, find the paired-selection context-building loop (the `for k = start_k, math.min(#subs, p2_l + Options.anki_context_lines)` loop that inserts into `ctx_parts`). Change `char_offset = char_offset + #text + 1` to `char_offset = char_offset + #text + 1` and change `table.concat(ctx_parts, " ")` to `table.concat(ctx_parts, "\0")`
- [ ] 2.2 In `dw_anki_export_selection`, find the single-word context-building loop (the `for k = start_k, math.min(#subs, cl + Options.anki_context_lines)` loop). Apply the same change: `table.concat(ctx_parts, "\0")`

## 3. Rewrite Sentence-Scoping in `extract_anki_context`

- [ ] 3.1 Locate the sentence-scoping block starting at line ~1729 (`if start_pos then`). Delete the backwards scan line: `local b_idx = pre:reverse():find("%s+[.!?]")`
- [ ] 3.2 Replace the deleted backwards scan with a NUL-based backwards scan: search `pre:reverse()` for `"\0"` (the first NUL going backwards = the nearest subtitle boundary before the selection). Calculate `sent_start` from that NUL position.
- [ ] 3.3 Replace the forwards scan line `local f_idx = post:find("[.!?]")` with a NUL-based forwards scan: `local f_idx = post:find("\0")`. If found, `sent_end = end_pos + f_idx - 1` (stop before the sentinel, not including it).
- [ ] 3.4 After extracting `raw_sub = full_line:sub(sent_start, sent_end)`, strip any residual `\0` characters from `raw_sub` before assigning to `sentence`.
- [ ] 3.5 Remove the `is_sentence_start` variable and the logic that conditionally appends a `"."` to the sentence inside `extract_anki_context` — this is now handled entirely by `is_sentence_boundary` set by the caller.

## 4. Add `is_abbrev` Helper Function

- [ ] 4.1 Define a local function `is_abbrev(w)` near the top of the Anki export section (before `dw_anki_export_selection`). It returns `true` if `w` matches one of:
  - `w:match("^%l+%.$") and #w <= 5` — short all-lowercase word ending with period (ca. bzw. usw. etc.)
  - `w:match("^%u%.$")` — single uppercase letter + period (a common German abbreviation prefix like `z.` when it comes out as a single token)
  - `w:match("^%u%.%u%.$")` — two-letter dotted abbreviation like `z.B.` if it comes as one token

## 5. Guard `is_sentence_boundary` Checks with `is_abbrev`

- [ ] 5.1 In `dw_anki_export_selection`, in the paired-selection branch: find the block `if prev_text and prev_text:match("[.!?]$") then is_sentence_boundary = true end` (line ~3661). Wrap it: only set `is_sentence_boundary = true` if additionally `not is_abbrev(prev_text)`.
- [ ] 5.2 In `dw_anki_export_selection`, in the single-word branch: find the check `if cw == 1 or (prev_text and prev_text:match("[.!?]$")) then is_sentence_boundary = true end` (line ~3689). Apply the same guard: `prev_text:match("[.!?]$") and not is_abbrev(prev_text)`.

## 6. Verification

- [ ] 6.1 Export a single word (`"Lebensmittel"`) from the subtitle `"[UMGEBUNG] Logistikpark Plattling Hier sind Firmen wie Kühne + Nagel (mit weiteren Kapazitäten), T.CON oder auch Verteilzentren für Lebensmittel (z."` — verify the exported context is the full subtitle text, not a fragment starting after `"(z."`.
- [ ] 6.2 Export a word from a subtitle containing `"Es liegt ca. 97 km"` — verify the exported context includes the full subtitle, not just `"97 km"`.
- [ ] 6.3 Export a genuine multi-word selection spanning two subtitle lines — verify `is_sentence_boundary` is still correctly set when the previous subtitle ended with a real sentence-ending word (e.g. `"Ende."`).
- [ ] 6.4 Verify no `\0` characters appear in any exported TSV field by inspecting the output file after test exports.
