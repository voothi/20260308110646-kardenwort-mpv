# Tasks: Anki Highlighter Implementation

## 1. Configuration & Input Setup

- [x] 1.1 In `lls_core.lua`, add `Options` properties: `dw_export_key = "MBTN_MID"`, `anki_context_max_words = 20`, `anki_context_lines = 3`, `anki_local_fuzzy_window = 10.0`, `anki_tsv_headers = "Term\\tContext"`, `anki_highlight_depth_1-3` (Rust palette).
- [x] 1.2 In `lls_core.lua`, add to the `FSM` table: `ANKI_HIGHLIGHTS = {}` and `ANKI_DB_PATH = nil`.
- [x] 1.3 In `input.conf`, map the `h` and `р` keys to a new script-binding named `toggle-anki-global`.
- [x] 1.4 In `lls_core.lua`, implement `toggle_anki_global()` function that flips `Options.anki_global_highlight`. Register the keybinding.
- [x] 1.5 Add `pcall` guards to all exported actions to prevent script failure on I/O issues or selection mismatches.

## 2. TSV Database Logic

- [x] 2.1 In `lls_core.lua`, implement `get_tsv_path()`. It grabs the current `path`, removes the extension, and appends `.tsv`.
- [x] 2.2 In `lls_core.lua`, implement `load_anki_tsv()`. Read file line by line, split by tabs. Assuming column 1 is the Term. Population `FSM.ANKI_HIGHLIGHTS`.
- [x] 2.3 Implement `save_anki_tsv_row(term, context, time_pos)` in `lls_core.lua`. Ensure automatic directory/file creation and header insertion. Use atomic swaps for in-memory updates.

## 3. Context & Sentence Processing

- [x] 3.1 Implement a helper `extract_anki_context(full_line, selected_term)` in `lls_core.lua`.
- [x] 3.2 **Sentence-First Logic**: Refine `extract_anki_context` to scan for `.`, `!`, `?` boundaries surrounding the selected word to isolate a grammatically complete slice.
- [x] 3.3 **Word Limit Safety**: If the isolated sentence exceeds `Options.anki_context_max_words`, perform word-based truncation with `...` indicators.

## 4. Drum Window Interaction (MBTN_MID)

- [x] 4.1 In `manage_dw_bindings`, map `MBTN_MID` to `cmd_dw_export_anki`.
- [x] 4.2 On MBTN_MID press, verify text selection. Support both multi-line selection and single-word-under-cursor clicks.
- [x] 4.3 Extract literal string and surrounding context using the sliding `anki_context_lines` window.
- [x] 4.4 Call `save_anki_tsv_row` and trigger OSD refresh. Fixed multibyte character handling in indexing.

## 5. Rendering & Shading Engine

- [x] 5.1 Implement `calculate_highlight_stack(target_word, time_pos)` in `lls_core.lua`.
- [x] 5.2 **Whole-Word Matching**: Update `calculate_highlight_stack` to split terms into word-lists and only match if the target word is exactly present (preventing `auf` matching `Aufgaben`).
- [x] 5.3 **Temporal Fuzzy Window**: Use `Options.anki_local_fuzzy_window` (10s) to allow stacking to work correctly across subtitle boundaries.
- [x] 5.4 Refactor `draw_drum` and `draw_dw` to evaluate stack depth for every word and inject corresponding Rust/Amber ASS tags.

## 6. Periodic Synchronization

- [x] 6.1 Add `anki_sync_period = 30` (or user-preferred `5`) to `Options`.
- [x] 6.2 Refactor `load_anki_tsv(force)` to support reload without UI flicker.
- [x] 6.3 Use `mp.add_periodic_timer` to automatically refresh highlights from disk every N seconds.
- [x] 6.4 Implement atomic loading to prevent database corruption during background syncs.
