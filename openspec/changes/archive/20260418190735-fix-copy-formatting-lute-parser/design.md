## Context

The Drum Window selection engine uses a scanner-based parser (Lute v3) to tokenize subtitle text into words, punctuation, and white space. While this ensures stable highlighting, the copy-to-clipboard and Anki-export functions are currently discarding non-word tokens and reconstructing text using a simple space-joining heuristic. This results in the loss of critical grammatical markers (like commas) and secondary formatting.

## Goals / Non-Goals

**Goals:**
- Preserve all punctuation and original spacing within a selected range.
- Ensure exported Anki terms match the verbatim text of the subtitle for accurate grounding.
- Maintain compatibility with the established "logical index" word selection system.

**Non-Goals:**
- Redefining word boundaries or changing how highlighting is calculated.
- Preserving ASS tags in the final copy (they should still be stripped for cleanliness).

## Decisions

### 1. Token-Weighted Range Extraction
Instead of re-parsing text into a word list, `cmd_dw_copy` and `dw_anki_export_selection` will use the full token stream from `build_word_list_internal(text, true)`.
- **RATIONALE**: The scanner already identifies word boundaries, punctuation, and whitespace. By iterating through original tokens and using `logical_idx` as anchors, we can "capture" everything between the first and last selected words without complex regex or heuristic re-joining.

### 2. Synchronization of Copy and Export Paths
Both the Ctrl+C (`cmd_dw_copy`) and Middle-Click (`dw_anki_export_selection`) logic will share the same range-extraction pattern.
- **RATIONALE**: Consistency is critical for user trust. If a user selects a phrase with a comma, they expect that comma to appear in the clipboard AND the Anki card.

### 3. Whitespace Normalization
We will continue to join multiple subtitle lines with a single space, but will preserve the original internal spacing of each line.
- **RATIONALE**: Subtitle lines are independent units; joining them with the original newline behavior in a single-line copy buffer is often undesirable, but internal punctuation and spacing of a phrase must be preserved.

## Risks / Trade-offs

- **[Risk]** Selection spanning multiple spaces or invisible metadata could result in messy clipboard text.
- **[Mitigation]** The existing `final_text:gsub("{[^}]+}", "")` and `match("^[%p%s]*(.-)[%p%s]*$")` logic will clean the final extracted block before it reaches the clipboard/Anki.
