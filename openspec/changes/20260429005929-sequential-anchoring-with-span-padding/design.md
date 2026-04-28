# Design: Sequential Anchoring & Adaptive Span Mapping

## 1. Sequential Forward Anchoring
The fallback anchor search for non-contiguous highlights now follows a two-pass approach:
1.  **Pivot Pass**: The first word of the selection is found using the closest-to-pivot distance to ground the search in the user's focus area.
2.  **Sequential Pass**: All subsequent words are searched for using `find(word, seq_pos, true)`, where `seq_pos` starts after the previous word's end.
- **Rationale**: This guarantees that the detected span follows the document's natural order, resolving ambiguity in sentences with repeated words (e.g., "bag six" vs "six five four").

## 2. Offset Mapping Robustness
To map character spans (`start_pos` to `end_pos`) to word indices, we must account for sentence cleaning.
- **Mechanism**:
    - Extract the raw substring using `sent_start` and `sent_end`.
    - Detect the length of any leading whitespace/punctuation that is stripped during cleaning.
    - `sentence_abs_start = sent_start + #lead`.
    - This `sentence_abs_start` is used as the base for all relative offset calculations, regardless of whether a synthetic "." is appended to the `sentence` later.

## 3. Wide Span Truncation Strategy
When the number of words in the selection span exceeds the `anki_context_max_words` limit:
- **Change**: Return `words[first_idx - pad .. last_idx + pad]`.
- **Default Pad**: 3 words.
- **Rationale**: If the user's selection is already very wide, they likely want to see those specific words. We provide a small "context buffer" around them instead of trying to fit a centered window that might cut off the edges of their selection.

## 4. Configuration Schema
- **New Option**: `anki_context_span_pad` (integer).
- **Integration**:
    - Added to the global `Options` table in `lls_core.lua`.
    - Documented and exposed in `mpv.conf` via `script-opts-append`.
