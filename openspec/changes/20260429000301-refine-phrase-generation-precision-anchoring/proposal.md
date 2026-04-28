# Proposal: Refine Phrase Generation with Precision Anchoring

## Problem
When exporting non-contiguous selections (paired highlights) to Anki, the `SentenceSource` (context) field is often truncated incorrectly, cutting off parts of the selection. This happens because the current truncation logic assumes that the selected words appear contiguously in the word list, which is false for split selections (e.g., "word1 ... word2").

## Objectives
- Ensure that the `SentenceSource` always contains all parts of a non-contiguous highlight.
- Improve the robustness of the "anchor" detection (finding the character span of the selection).
- Strictly respect word limits while prioritizing the visibility of the selected words.

## Proposed Changes
- **Anchoring**: Update the fallback loop in `extract_anki_context` to specifically ignore synthetic `...` tokens when searching for word anchors.
- **Truncation Mapping**: Replace the fragile word-matching search in the truncation logic with a character-relative mapping. This uses the already-known character span of the highlight to identify exactly which words in the sentence list are "inside" the selection.
- **Viewport Selection**: Implement a "centered and shifted" viewport algorithm that centers on the selection but shifts left/right to ensure the boundaries of the selection are included in the final context.

## Success Criteria
- Paired highlights spanning multiple words or sentences are exported with a context that includes all highlighted terms.
- The context field respects the `anki_context_max_words` limit without cutting off the core selection.
- Verbatim matches continue to work as expected.
