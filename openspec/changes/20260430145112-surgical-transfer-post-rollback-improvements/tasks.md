## 1. Phase A — Specification Transfer (Zero Code Changes)

- [ ] 1.1 Verify that all 6 spec files in this change's `specs/` directory are consistent with the current codebase at commit `131f530` (`20260429210156`). Flag any requirements that describe behavior not present in the stable code — these are aspirational and must be marked as such.
- [ ] 1.2 Confirm that existing `openspec/specs/anki-highlighting/spec.md` does not conflict with the new Character-Offset Precision Anchoring requirement. Verify backward-compatibility clause with existing TSV records.
- [ ] 1.3 Confirm that existing `openspec/specs/unified-drum-rendering/spec.md` does not conflict with the new Rendering Pipeline Immutability Guard and Semantic Punctuation Post-Processing Integration Point requirements.
- [ ] 1.4 Archive the two superseded open change projects (`20260429185737-rework-string-preparation-for-export` and `20260429195210-unify-subtitle-export-and-keyboard-granularity`) as "superseded by `20260430145112`".

## 2. Phase B — Export Engine Unification (Isolated, Non-Rendering Code)

- [ ] 2.1 Relocate scope-critical constants (`L_EPSILON`) and comparison helpers (`logical_cmp`, `is_word_token`) to the top of the logic section in `lls_core.lua`, before any function that references them.
- [ ] 2.2 Implement the `prepare_export_text(selection_type, selection_data, opts)` pure function in `lls_core.lua`. Must handle RANGE (Yellow), SET (Pink), and POINT (single word) selections with verbatim token joining using `build_word_list_internal(text, true)` and `table.concat`.
- [ ] 2.3 Implement fractional index boundary checks using strict `>=` / `<=` comparisons against `logical_idx` for symbol-level precision.
- [ ] 2.4 Implement token-lookbehind logic in `prepare_export_text` for SET mode: when adjacent Pink members are on the same line, pull verbatim intermediate tokens (hyphens, slashes) instead of injecting space.
- [ ] 2.5 Centralize terminal punctuation restoration (`[.!?]`) into `prepare_export_text`, gated by `restore_sentence=true` parameter.
- [ ] 2.6 Refactor `clean_anki_term`: remove aggressive leading/trailing punctuation stripping. Preserve ASS tag removal, space normalization. Stop stripping symbols that were explicitly part of the selection range.
- [ ] 2.7 Wire call site `cmd_dw_copy` to use `prepare_export_text` for verbatim clipboard copy.
- [ ] 2.8 Wire call site `cmd_copy_sub` to use `prepare_export_text` (with Russian filter support preserved).
- [ ] 2.9 Wire call site `dw_anki_export_selection` to use `prepare_export_text` for Yellow/Range mining.
- [ ] 2.10 Wire call site `ctrl_commit_set` to use `prepare_export_text` for Pink/Set mining.
- [ ] 2.11 **Verification**: Test mouse selection of `[Musik]` — full brackets selected → export includes brackets. Only "Musik" clicked → export without brackets.
- [ ] 2.12 **Verification**: Test Pink selection of `Marken` + `Discount` with intermediate `-` → export produces "Marken-Discount".
- [ ] 2.13 **Verification**: Test terminal punctuation restoration in both Yellow and Pink modes.
- [ ] 2.14 **Regression Check**: Verify that all existing export behaviors (Ctrl+C copy, MMB export, Context Copy x/z modes) continue to work. Compare with commit `131f530` baseline.

## 3. Phase C — Keyboard Selection Granularity (Isolated Navigation Code)

- [ ] 3.1 Update `cmd_dw_word_move` to implement Shift-aware navigation: when `shift=true`, filter for ALL logical tokens (including symbols); when `shift=false`, filter for words only (current behavior, unchanged).
- [ ] 3.2 Implement epsilon-aware comparison in `dw_compute_word_center_x` to correctly position the cursor over fractional logical indices (symbols).
- [ ] 3.3 Update `draw_dw` rendering pass to correctly highlight symbols (fractional logical indices) when they fall within the selection range.
- [ ] 3.4 **Verification**: Navigate with Shift+Right from "Hello" in "Hello, world!" — cursor lands on comma. Standard Right from comma lands on "world".
- [ ] 3.5 **Verification**: Selection range from word to symbol includes all intermediate tokens in the highlight.
- [ ] 3.6 **Regression Check**: Verify standard arrow navigation, Ctrl+Arrow jump, and existing Shift+Arrow selection behavior are unchanged.

## 4. Phase D — Semantic Punctuation Coloring (Guarded Rendering Post-Pass)

- [ ] 4.1 Implement `apply_semantic_punctuation_colors(color_array, token_list)` function in `lls_core.lua`. This function reads the finalized `color_array` and fills in uncolored punctuation token slots by propagating colors from adjacent colored words.
- [ ] 4.2 Implement forward propagation: if a word is colored and the next token is an uncolored punctuation, assign the word's color to the punctuation.
- [ ] 4.3 Implement backward propagation: if a punctuation token is uncolored and the next word token is colored, assign the word's color to the punctuation.
- [ ] 4.4 Implement whitespace skip: the propagation scan must skip whitespace tokens to reach adjacent punctuation across spaces.
- [ ] 4.5 Implement cross-subtitle propagation: the scan must operate across the full visible token sequence (all subtitle entries in the rendering window), not just within individual lines.
- [ ] 4.6 Implement priority guard: never overwrite existing non-zero color assignments (selection colors, intersection colors, depth colors).
- [ ] 4.7 Integrate the post-pass call into `draw_drum`: call `apply_semantic_punctuation_colors` AFTER `calculate_highlight_stack` and BEFORE ASS string assembly.
- [ ] 4.8 Integrate the post-pass call into `draw_dw`: identical integration point.
- [ ] 4.9 **Verification**: Word "Welt" highlighted in Orange, followed by "!" → "!" turns Orange.
- [ ] 4.10 **Verification**: "[Musik]" with "Musik" highlighted → both brackets turn the same color.
- [ ] 4.11 **Verification**: Brick-colored punctuation (existing intersection) is NOT overwritten.
- [ ] 4.12 **Regression Check**: Verify that `calculate_highlight_stack` is UNMODIFIED. Run full diff against commit `131f530` for this function — it must be byte-identical.
- [ ] 4.13 **Regression Check**: Verify Drum Mode C activates, hit-zones align, clicks target correct words.

## 5. Phase E — Performance Caching (Transparent Optimization)

- [ ] 5.1 Implement `FSM.ANKI_WORD_MAP` as a normalized lookup table. Rebuild on every TSV reload in the periodic sync handler.
- [ ] 5.2 Replace linear highlight scans in the rendering loop with O(1) word map lookups.
- [ ] 5.3 Implement `DRUM_LAYOUT_CACHE` keyed by subtitle index — cache `calculate_osd_line_meta` results.
- [ ] 5.4 Implement `DRUM_DRAW_CACHE` keyed by (subtitle_index, highlight_fingerprint, selection_state) — cache final ASS string.
- [ ] 5.5 Implement cache invalidation triggers: TSV reload, subtitle index change, selection change, highlight toggle (h key).
- [ ] 5.6 **Verification**: Measure rendering performance before and after caching on a file with 200+ highlights. Confirm measurable CPU reduction.
- [ ] 5.7 **Verification**: Force cache invalidation and verify re-rendered output is byte-identical to cached version.
- [ ] 5.8 **Regression Check**: Full functional test of all modes (Drum C, Window W, Book Mode, Search, Tooltip) with caching enabled.
