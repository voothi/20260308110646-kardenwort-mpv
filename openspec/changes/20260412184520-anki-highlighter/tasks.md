# Tasks: Anki Highlighter Implementation

- [x] **1. Instrumentation & Config**
    - [x] 1.1 In `lls_core.lua`, add `Options` properties: `dw_export_key = "MBTN_MID"`, `anki_context_max_words = 20`, `anki_context_lines = 3`, `anki_local_fuzzy_window = 10.0`, `anki_tsv_headers = "Term\\tContext"`, `anki_highlight_depth_1-3` (Rust palette).
    - [x] 1.2 Implement sentence-aware extraction logic using `.!?` boundary sensing.
    - [x] 1.3 Implement whole-word matching in `calculate_highlight_stack` using `build_word_list`.
    - [x] 1.4 Wrap sync and export logic in `pcall` guards to prevent script failure on I/O issues.
    - [x] 1.5 Map the `h` and `р` keys to `toggle-anki-global` in `input.conf`.

- [x] **2. Rendering Engine**
    - [x] 2.1 Refactor `draw_drum` and `draw_dw` to iterate through words and check the highlight stack.
    - [x] 2.2 Implement ASS tag injection for depth-based coloring.
    - [x] 2.3 Ensure word indices remain aligned when multi-line context is used.

- [x] **3. Data Persistence**
    - [x] 3.1 Implement `save_anki_tsv_row` with automatic file/parent creation.
    - [x] 3.2 Implement `load_anki_tsv` with atomic loading to prevent UI flickering.
    - [x] 3.3 Set up a periodic background timer for auto-syncing the database.

- [x] **4. Validation & Hardening**
    - [x] 4.1 Test multi-subtitle spanning selections.
    - [x] 4.2 Verify sentence boundaries (avoiding previous sentence bleeding).
    - [x] 4.3 Verify whole-word isolation (e.g., `auf` vs `Aufgaben`).
