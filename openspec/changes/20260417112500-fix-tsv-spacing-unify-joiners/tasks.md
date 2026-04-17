## 1. Unified Joiner Service

- [ ] 1.1 Update `compose_term_smart` (line 505) in `lls_core.lua` to expand punctuation rules for all common European languages.
- [ ] 1.2 Include Unicode symbols like `…`, `¿`, `¡`, and various smart quotes in the no-space lists.

## 2. Refactor Context Building

- [ ] 2.1 Modify `dw_anki_export_selection` (around lines 2495 and 2516) to build `context_line` from raw `subs[k].text`.
- [ ] 2.2 Re-verify that the existing context cleaning (tag stripping at line 2567 onwards) remains effective and does not introduce leading/trailing spaces.

## 3. Propagation & Consistency

- [ ] 3.1 Update `extract_anki_context` fallback (line 1119) to use `compose_term_smart` instead of raw space concatenation.
- [ ] 3.2 Update `draw_drum` smart joiner loop (around lines 1789-1795) to call `compose_term_smart`.

## 4. Validation

- [ ] 4.1 Perform an Anki export with punctuation (e.g. `ehrlich,`). Verify TSV shows no extra space before the comma.
- [ ] 4.2 Test with non-contiguous word selection (Ctrl-MMB) to ensure `compose_term_smart` handles gaps correctly.
- [ ] 4.3 Toggle `dw_original_spacing` OFF in `mpv.conf` and verify on-screen display remains naturally spaced.
