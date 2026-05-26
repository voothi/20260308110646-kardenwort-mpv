## 1. Configuration

- [x] 1.1 Preserve sentence extraction as the default and compatibility path
- [x] 1.2 Add `anki_context_words_before` and `anki_context_words_after` to `Options` and normalize them as non-negative integers
- [x] 1.3 Update `mpv.conf` examples or documentation with concise examples for sentence-only and sentence-plus-padding

## 2. Context Extraction Refactor

- [x] 2.1 Factor selected-span anchoring so sentence extraction and padding extension share the same `start_pos` / `end_pos` detection
- [x] 2.2 Factor word-span indexing over the joined context so logical word counts can map back to literal source substring boundaries
- [x] 2.3 Preserve non-word structural markers such as `##` and `###` inside extracted substrings without counting them as padding words
- [x] 2.4 Keep `\0` subtitle sentinels internal to extraction and replace them with spaces only in the exported context

## 3. Padding Extension

- [x] 3.1 Preserve `sentence` behavior as the primary extraction path for manual subtitles
- [x] 3.2 Apply before/after word expansion after the sentence-scoped base span is found

## 4. Truncation Integration

- [x] 4.1 In sentence + padding flow, raise the effective truncation limit enough to retain the selected span plus configured padding when available
- [x] 4.2 Update wide-selection crop behavior so explicit before/after padding overrides the smaller fixed span pad when active

## 5. Focused Verification

- [x] 5.1 Add or update focused tests for default `sentence` behavior remaining unchanged
- [x] 5.2 Add a focused test for sentence + padding with `Verkehrs-Ausbildungs-Zentrum i. d. Opf. GmbH`
- [x] 5.3 Add a focused test for clamping before/after padding at joined-context boundaries
