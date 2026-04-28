## 1. Preparation & Baseline

- [x] 1.1 **Grounding Baseline**: Create a non-contiguous (Pink) selection for a separable verb (e.g., "pick ... on") in a subtitle line exceeding 150 characters.
- [x] 1.2 **Verify Regression**: Trigger Anki export and confirm that `SentenceSource` in the TSV is truncated to 100 characters and ends with `...`.

## 2. Core Logic Refactoring (lls_core.lua)

- [x] 2.1 **Ellipsis-Neutral Tokenization**: Modify `extract_anki_context` to filter out literal `...` tokens when splitting the `selected_term` into `selected_words`.
- [x] 2.2 **Span-Based Anchoring**: Replace the contiguous `target_idx` loop with a logic that finds the first and last word indices of all `selected_words` within the sentence block.
- [x] 2.3 **Midpoint Centering**: Update the word-count truncation logic to use the midpoint of the detected word span as the pivot for extracting context words.
- [x] 2.4 **Fallback Removal**: Remove the legacy string-based truncation `sentence:sub(1, 100) .. "..."` to eliminate artificial data loss and trailing ellipses.
- [x] 2.5 **Precision Anchoring**: Use the calculated character coordinates (`start_pos`/`end_pos`) to find exact word indices, preventing over-expansion from duplicate words.

## 3. Verification & Compliance

- [x] 3.1 **Split-Phrase Export**: Verify that exporting split phrases from long lines now preserves all selected words within a centered context window.
- [x] 3.2 **Formatting Audit**: Confirm that the exported `SentenceSource` no longer contains the hardcoded `...` suffix unless the original subtitle text contained it.
- [x] 3.3 **Spec Parity**: Ensure `SentenceSource` generation complies with the new "Split-Phrase Context Grounding" requirement.
