## 1. Configuration & Input Setup

- [x] 1.1 In `lls_core.lua`, add `Options` properties: `dw_export_key = "MBTN_MID"`, `anki_context_max_words = 20`, `anki_context_lines = 1`, `anki_tsv_headers = "Term\\tContext"`, `anki_highlight_depth_1 = "00A5FF"`, `anki_highlight_depth_2 = "0066CC"`, `anki_highlight_depth_3 = "003399"`, `anki_global_highlight = true`.
- [x] 1.2 In `lls_core.lua`, add to the `FSM` table: `ANKI_HIGHLIGHTS = {}` and `ANKI_DB_PATH = nil`.
- [x] 1.3 In `input.conf`, map the `h` and `р` keys to a new script-binding named `toggle-anki-global`.
- [x] 1.4 In `lls_core.lua`, implement `toggle_anki_global()` function that flips `Options.anki_global_highlight`, prints an OSD message showing the new state, and forces a subtitle redraw (`drum_osd:update()`). Register the keybinding.

## 2. TSV Database Logic

- [x] 2.1 In `lls_core.lua`, implement `get_tsv_path()`. It should grab the current `path` via mp.get_property, remove the extension (`.mkv`, etc.), and append `.tsv`. Store this in `FSM.ANKI_DB_PATH`.
- [x] 2.2 In `lls_core.lua`, implement `load_anki_tsv()`. If the file at `FSM.ANKI_DB_PATH` exists, read it line by line, split by tabs. Assuming column 1 is the Term, populate `FSM.ANKI_HIGHLIGHTS` as a table (e.g. `{ [term1] = { time = t }, [term2] = { time = t } }`). Hook this to trigger dynamically when media loads (e.g. inside `update_media_state()`).
- [x] 2.3 Implement `save_anki_tsv_row(term, context, time_pos)` in `lls_core.lua`. This function should format the string according to `anki_tsv_headers`. If the file is empty/missing, it must first write the headers. Then it appends the new row. It should also update the in-memory `FSM.ANKI_HIGHLIGHTS` table immediately.

## 3. Context Processing

- [x] 3.1 Implement a helper `extract_anki_context(full_line, selected_term)` in `lls_core.lua`.
- [x] 3.2 Ensure `extract_anki_context` tokenizes the `full_line` into words. If the count exceeds `Options.anki_context_max_words`, it should reconstruct a truncated string by taking the words surrounding the `selected_term` and prepending/appending `...` to indicate omitted boundaries. If it's short enough, just return the `full_line`.

## 4. Drum Window Interaction (MBTN_MID)

- [x] 4.1 In the `dw_input_handlers` table or equivalent event listener architecture in `lls_core.lua`, add intercept logic for `MBTN_MID` (or dynamic binding `Options.dw_export_key`).
- [x] 4.2 On MBTN_MID press, verify the user has an active text selection in the Drum Window (`FSM.DW_ANCHOR_WORD ~= -1`).
- [x] 4.3 Extract the exact literal selected string from the layout matrix (`cl, cw` to `al, aw`), and obtain the full line string representing the context.
- [x] 4.4 Calculate the current `time_pos` associated with that subtitle line, and call `save_anki_tsv_row(selected_string, clean_context, time_pos)`.
- [x] 4.5 Trigger an immediate Drum Window OSD refresh so the new highlight is rendered on screen.

## 5. Rendering & Shading Engine

- [x] 5.1 Create a helper function `calculate_highlight_stack(target_word, time_pos)` in `lls_core.lua`. It iterates `FSM.ANKI_HIGHLIGHTS`. If `anki_global_highlight` is true, check if `target_word` matches exactly or is an exact substring of the highlight term. If false, it must match AND the `time_pos` must be within `+/- 2` seconds of the highlight's original time. It returns an integer (0, 1, 2, etc.) representing overlap depth.
- [x] 5.2 Refactor the subtitle string generation (likely inside `draw_drum` or formatting loops) from a monolithic block insertion to a word-by-word builder.
- [x] 5.3 As each word is concatenated for rendering, evaluate `calculate_highlight_stack`. If `stack == 1`, inject `{\\c&H` + `Options.anki_highlight_depth_1` + `&}` before the word. If `stack >= 2`, inject `depth_2`. If `stack >= 3`, inject `depth_3`. Reset to the default context color `{\\c&H[default]&}` after the highlighted string boundary finishes.
- [x] 5.4 Ensure both `draw_dw` (Drum Window) and `draw_drum` (Timeline Drum Mode) utilize this enhanced text builder so highlights display accurately in both views.

## 6. Periodic Synchronization

- [x] 6.1 Add `anki_sync_period = 30` (or user-preferred `5`) to `Options` in `lls_core.lua`.
- [x] 6.2 Refactor `load_anki_tsv(force)` to support force-reloading the dictionary from disk.
- [x] 6.3 Use an atomic swap (local `new_highlights` table) inside `load_anki_tsv` to prevent state corruption during the async-like sync.
- [x] 6.4 Initialize a `mp.add_periodic_timer` in the script's entry point that calls the force-sync and updates the OSD.
- [x] 6.5 Update `mpv.conf` with the synchronization interval.
