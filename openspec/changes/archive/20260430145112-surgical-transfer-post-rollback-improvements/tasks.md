## 1. Phase A — Specification Transfer (Zero Code Changes)

- [x] 1.1 Verify that all 6 spec files in this change's `specs/` directory are consistent with the current codebase at commit `131f530` (`20260429210156`). Flag any requirements that describe behavior not present in the stable code — these are aspirational and must be marked as such.
- [x] 1.2 Confirm that existing `openspec/specs/anki-highlighting/spec.md` does not conflict with the new Character-Offset Precision Anchoring requirement. Verify backward-compatibility clause with existing TSV records.
- [x] 1.3 Confirm that existing `openspec/specs/unified-drum-rendering/spec.md` does not conflict with the new Rendering Pipeline Immutability Guard and Semantic Punctuation Post-Processing Integration Point requirements.
- [x] 1.4 Archive the two superseded open change projects (`20260429185737-rework-string-preparation-for-export` and `20260429195210-unify-subtitle-export-and-keyboard-granularity`) as "superseded by `20260430145112`".

## 2. Phase B — Export Engine Unification (Isolated, Non-Rendering Code)

- [x] 2.1 Relocate scope-critical constants (`L_EPSILON`) and comparison helpers (`logical_cmp`, `is_word_token`) to the top of the logic section in `lls_core.lua`, before any function that references them.
- [x] 2.2 Implement the `prepare_export_text(selection_type, selection_data, opts)` pure function in `lls_core.lua`. Must handle RANGE (Yellow), SET (Pink), and POINT (single word) selections with verbatim token joining using `build_word_list_internal(text, true)` and `table.concat`.
- [x] 2.3 Implement fractional index boundary checks using strict `>=` / `<=` comparisons against `logical_idx` for symbol-level precision.
- [x] 2.4 Implement token-lookbehind logic in `prepare_export_text` for SET mode: when adjacent Pink members are on the same line, pull verbatim intermediate tokens (hyphens, slashes) instead of injecting space.
- [x] 2.5 Centralize terminal punctuation restoration (`[.!?]`) into `prepare_export_text`, gated by `restore_sentence=true` parameter.
- [x] 2.6 Refactor `clean_anki_term`: remove aggressive leading/trailing punctuation stripping. Preserve ASS tag removal, space normalization. Stop stripping symbols that were explicitly part of the selection range.
- [x] 2.7 Wire call site `cmd_dw_copy` to use `prepare_export_text` for verbatim clipboard copy.
- [x] 2.8 Wire call site `cmd_copy_sub` to use `prepare_export_text` (with Russian filter support preserved).
- [x] 2.9 Wire call site `dw_anki_export_selection` to use `prepare_export_text` for Yellow/Range mining.
- [x] 2.10 Wire call site `ctrl_commit_set` to use `prepare_export_text` for Pink/Set mining.
- [x] 2.11 **Verification**: Test mouse selection of `[Musik]` — full brackets selected → export includes brackets. Only "Musik" clicked → export without brackets.
- [x] 2.12 **Verification**: Test Pink selection of `Marken` + `Discount` with intermediate `-` → export produces "Marken-Discount".
- [x] 2.13 **Verification**: Test terminal punctuation restoration in both Yellow and Pink modes.
- [x] 2.14 **Regression Check**: Verify that all existing export behaviors (Ctrl+C copy, MMB export, Context Copy x/z modes) continue to work. Compare with commit `131f530` baseline.

## 3. Phase C — Keyboard Selection Granularity (Isolated Navigation Code)

- [x] 3.1 Update `cmd_dw_word_move` to implement Shift-aware navigation: when `shift=true`, filter for ALL logical tokens (including symbols); when `shift=false`, filter for words only (current behavior, unchanged).
- [x] 3.2 Implement epsilon-aware comparison in `dw_compute_word_center_x` to correctly position the cursor over fractional logical indices (symbols).
- [x] 3.3 Update `draw_dw` rendering pass to correctly highlight symbols (fractional logical indices) when they fall within the selection range.
- [x] 3.4 **Verification**: Navigate with Shift+Right from "Hello" in "Hello, world!" — cursor lands on comma. Standard Right from comma lands on "world".
- [x] 3.5 **Verification**: Selection range from word to symbol includes all intermediate tokens in the highlight.
- [x] 3.6 **Regression Check**: Verify standard arrow navigation, Ctrl+Arrow jump, and existing Shift+Arrow selection behavior are unchanged.

## 4. Phase D — Semantic Punctuation Coloring (Guarded Rendering Post-Pass)

- [x] 4.1 Implement `apply_semantic_punctuation_colors(color_array, token_list)` function in `lls_core.lua`. This function reads the finalized `color_array` and fills in uncolored punctuation token slots by propagating colors from adjacent colored words.
- [x] 4.2 Implement forward propagation: if a word is colored and the next token is an uncolored punctuation, assign the word's color to the punctuation.
- [x] 4.3 Implement backward propagation: if a punctuation token is uncolored and the next word token is colored, assign the word's color to the punctuation.
- [x] 4.4 Implement whitespace skip: the propagation scan must skip whitespace tokens to reach adjacent punctuation across spaces.
- [x] 4.5 Implement cross-subtitle propagation: the scan must operate across the full visible token sequence (all subtitle entries in the rendering window), not just within individual lines.
- [x] 4.6 Implement priority guard: never overwrite existing non-zero color assignments (selection colors, intersection colors, depth colors).
- [x] 4.7 Integrate the post-pass call into `draw_drum`: call `apply_semantic_punctuation_colors` AFTER `calculate_highlight_stack` and BEFORE ASS string assembly.
- [x] 4.8 Integrate the post-pass call into `draw_dw`: identical integration point.
- [x] 4.9 **Verification**: Open `[Musik]` where `[` is in sub 100 and `Musik]` is in sub 101. Both should be colored with the same highlight (DB phrase).
- [x] 4.10 **Verification**: Selection of "Word!" should color "!" with the selection color.
- [x] 4.11 **Verification**: Verify that uncolored punctuation between two differently colored phrases stays uncolored (unless it's part of one).
- [x] 4.12 **Regression Check**: Verify that `calculate_highlight_stack` is UNMODIFIED. Run full diff against commit `131f530` for this function — it must be byte-identical.
- [x] 4.13 **Regression Check**: Verify Drum Mode C activates, hit-zones align, clicks target correct words.

## 5. Phase E — Performance Caching (Transparent Optimization)

- [x] 5.1 Initialize `DRUM_LAYOUT_CACHE` and `DRUM_DRAW_CACHE` tables in `lls_core.lua`.
- [x] 5.2 Implement layout caching in `calculate_osd_line_meta`: check if `sub_text` and `size` are identical to cached version; if so, return cached metadata.
- [x] 5.3 Implement draw caching in `draw_drum`: if `center_idx` and `FSM` versions are identical, return cached ASS.
- [x] 5.4 Implement O(1) word-map indexing: update `calculate_highlight_stack` to use a pre-computed word_map (if available) instead of linear string scans.
- [x] 5.5 **Regression Check**: Verify that Drum Mode activates and all highlights appear correctly (O(1) lookups must return identical results).
- [x] 5.6 **Regression Check**: Verify that clicking a word still highlights it (caching must not block interactive updates).
- [x] 5.7 **Verification**: Force cache invalidation and verify re-rendered output is byte-identical to cached version.
- [x] 5.8 **Regression Check**: Full functional test of all modes (Drum C, Window W, Book Mode, Search, Tooltip) with caching enabled.
