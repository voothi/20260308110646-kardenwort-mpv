## 1. Tokenizer Updates

- [ ] 1.1 Update `build_word_list_internal` in `lls_core.lua` to atomize `\N` and `\h` tokens.
- [ ] 1.2 Verify that line-break tokens are correctly identified and do not split into individual characters.

## 2. Shared Semantic Engine

- [ ] 2.1 Implement `is_ignorable_for_semantic_pass` helper in the rendering utils section.
- [ ] 2.2 Implement `populate_token_meta` shared utility to handle Pass 1 (Priority calculation).
- [ ] 2.3 Implement `get_global_neighbor` recursive search helper for cross-subtitle traversal.
- [ ] 2.4 Implement `apply_global_semantic_pass` to handle Pass 2 (Color flow).

## 3. Drum Mode (C) Refactor

- [ ] 3.1 Modify `draw_drum` to collect and populate `token_meta` for the entire context range.
- [ ] 3.2 Apply the global semantic pass to the collected `sub_metas`.
- [ ] 3.3 Update `format_sub_wrapped` to utilize the pre-calculated `token_meta`.
- [ ] 3.4 Verify visual consistency for wrapped brackets in Drum Mode.

## 4. Drum Window (W) Refactor

- [ ] 4.1 Modify `draw_dw` to populate `token_meta` for all entries in the current layout.
- [ ] 4.2 Apply the global semantic pass across the entire `layout` list.
- [ ] 4.3 Remove redundant localized selection and semantic logic from the rendering loop.
- [ ] 4.4 Verify that brackets at subtitle boundaries correctly inherit colors in the Drum Window.

## 5. Final Audit

- [ ] 5.1 Compare C mode and W mode side-by-side with complex boundary cases.
- [ ] 5.2 Verify that performance remains stable during rapid scrolling in W mode.
