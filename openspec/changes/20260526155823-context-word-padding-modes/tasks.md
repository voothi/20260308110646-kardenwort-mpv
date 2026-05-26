## 1. Configuration

- [ ] 1.1 Add `anki_context_scope_mode` to `Options` with supported values `sentence`, `sentence-word-padding`, `word-window`, and `auto`
- [ ] 1.2 Add `anki_context_words_before` and `anki_context_words_after` to `Options` and normalize them as non-negative integers
- [ ] 1.3 Update `mpv.conf` examples or documentation with concise examples for sentence-only, sentence-plus-padding, word-window, and auto behavior

## 2. Context Extraction Refactor

- [ ] 2.1 Factor selected-span anchoring so sentence and word-window modes share the same `start_pos` / `end_pos` detection
- [ ] 2.2 Factor word-span indexing over the joined context so logical word counts can map back to literal source substring boundaries
- [ ] 2.3 Preserve non-word structural markers such as `##` and `###` inside extracted substrings without counting them as padding words
- [ ] 2.4 Keep `\0` subtitle sentinels internal to extraction and replace them with spaces only in the exported context

## 3. Mode Dispatch

- [ ] 3.1 Implement `sentence` mode as the current abbreviation-aware punctuation-scoped behavior
- [ ] 3.2 Implement `sentence-word-padding` by applying before/after word expansion after the sentence-scoped base span is found
- [ ] 3.3 Implement `word-window` by bypassing sentence-terminator scanning and using selected span plus configured before/after words
- [ ] 3.4 Implement `auto` dispatch with safe fallback to `sentence` when auto-subtitle detection is uncertain
- [ ] 3.5 Ensure invalid `anki_context_scope_mode` values fall back to `sentence`

## 4. Truncation Integration

- [ ] 4.1 Skip adaptive word-count truncation for `word-window` because the mode is already explicitly bounded
- [ ] 4.2 In `sentence-word-padding`, raise the effective truncation limit enough to retain the selected span plus configured padding when available
- [ ] 4.3 Update wide-selection crop behavior so explicit before/after padding overrides the smaller fixed span pad when active

## 5. Focused Verification

- [ ] 5.1 Add or update focused tests for default `sentence` behavior remaining unchanged
- [ ] 5.2 Add a focused test for `sentence-word-padding` with `Verkehrs-Ausbildungs-Zentrum i. d. Opf. GmbH`
- [ ] 5.3 Add a focused test that `word-window` bypasses punctuation and abbreviation scanning
- [ ] 5.4 Add a focused test for clamping before/after padding at joined-context boundaries
- [ ] 5.5 Add a focused test for `auto` mode using a controlled auto-subtitle detection signal or fallback case
