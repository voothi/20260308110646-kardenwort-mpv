# Tasks: Modularize LLS Core and Reduce Complexity

## 1. Infrastructure Setup

- [ ] 1.1 Create `scripts/lib/` directory for modularized components.
- [ ] 1.2 Implement a robust module loader in `lls_core.lua` using `require`.
- [ ] 1.3 Setup a global event bus or shared state bridge between modules.

## 2. Diagnostic & Configuration Refactor

- [ ] 2.1 Extract `Diagnostic` table and `validate_config` logic to `scripts/lib/diagnostic.lua`.
- [ ] 2.2 Update `lls_core.lua` to use the new diagnostic module for all logging.
- [ ] 2.3 Verify startup health check continues to function correctly.

## 3. Subtitle Parsing & Tokenization

- [ ] 3.1 Extract `load_sub`, `parse_time`, and `build_word_list_internal` to `scripts/lib/sub_parser.lua`.
- [ ] 3.2 Standardize the `Subtitle` object structure across the codebase.
- [ ] 3.3 Ensure caching of tokens and visual lines is preserved in the new module.

## 4. Anki Logic & Highlighting Pipeline

- [ ] 4.1 Migrate Anki TSV/Mapping logic to `scripts/lib/anki_manager.lua`.
- [ ] 4.2 Refactor `calculate_highlight_stack` into a discrete pipeline (Filter -> Match -> Ground -> Stack).
- [ ] 4.3 Optimize the binary search for candidates to handle large highlight databases (10k+ entries).

## 5. Search Engine Decoupling

- [ ] 5.1 Move `calculate_match_score` and result sorting logic to `scripts/lib/search_engine.lua`.
- [ ] 5.2 Separate search input handling from search result rendering.
- [ ] 5.3 Implement a "Lazy Search" mode to prevent OSD stuttering on long queries.

## 6. Rendering Standardization

- [ ] 6.1 Create `scripts/lib/ui_renderer.lua` for all ASS tag generation and alpha calculations.
- [ ] 6.2 Migrate `draw_drum`, `draw_dw`, and `draw_dw_tooltip` to the new renderer.
- [ ] 6.3 Implement a unified `HitZoneManager` to track interactive OSD regions.

## 7. Integration & Cleanup

- [ ] 7.1 Perform a surgical reduction of `lls_core.lua`, removing migrated logic.
- [ ] 7.2 Conduct end-to-end testing of SRT, Drum, and Drum Window modes.
- [ ] 7.3 Verify Anki export and Search HUD interaction parity with v1.58.18.
