## Why

The current Anki context extraction logic in `lls_core.lua` is over-eager when searching for sentence boundaries. It searches for punctuation starting from the *beginning* of the selected term. If the user selects a range that includes a period (e.g., spanning two sentences), the current logic stops at the first period it finds inside the term, cutting off the remainder of the selection in the "Sentence Source" field.

Furthermore, the default truncation limit of 20 words is often too restrictive for complex German (B2 level) sentences, leading to incomplete context even when boundaries are correctly identified.

## What Changes

- **Forward Search Logic**: Update `extract_anki_context` to search for sentence-ending punctuation starting from the *end* of the selected term. This ensures that the context captures the full sentences encompassing the entire selection.
- **Adaptive Truncation**: Increase the default `anki_context_max_words` limit and implement a more balanced truncation heuristic that respects long selections.
- **Improved Context Integrity**: Ensure that if a selection spans multiple sentences, the resulting context includes all involved sentences in their entirety (within updated limits).
- **Metadata Tag Filtering**: Implement automatic stripping of bracketed metadata tags (e.g., `[musik]`, `[Lachen]`) from exported terms and sentences to improve flashcard quality.

## Capabilities

### New Capabilities
- `adaptive-context-truncation`: A logic extension that adjusts the word-count window dynamically based on the length of the selected term to ensure surrounding context is not lost for long phrases.
- `metadata-tag-filtering`: Automatic removal of bracketed subtitle tags during export, configurable via `anki_strip_metadata`.

### Modified Capabilities
- `anki-highlighting`: Update the "Sentence-Aware Context Extraction" requirement to handle selections spanning multiple sentences and adjust truncation behavior.

## Impact

- `scripts/lls_core.lua`: Refactor `extract_anki_context` and update default `Options`.
- `script-opts/lls.conf`: (Informational) Users can now set higher word limits.
