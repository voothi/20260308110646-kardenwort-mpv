# Design: Precision Anchoring & Viewport Mapping

## Core Mechanism

The refinement centers on `extract_anki_context` in `lls_core.lua`. The process is divided into three phases:

### Phase 1: Robust Anchoring
When a verbatim match for `selected_term` fails (common in non-contiguous mode D), we fall back to a word-by-word search.
- **Change**: Skip the `...` token during this search.
- **Rationale**: `...` is a synthetic joiner added by the script. Searching for it in the source text is useless and potentially misleading.
- **Result**: `start_pos` and `end_pos` correctly define the absolute character range covering all picked words.

### Phase 2: Precision Truncation Mapping
If the sentence is too long and needs truncation, we must identify which words in the `words` list (built from the sentence) correspond to our selection.
- **Change**: Calculate `s_rel` and `e_rel` (sentence-relative character offsets) using `start_pos` and `sent_start`.
- **Change**: Iterate through the `words` list and track their character positions in the sentence. Any word that overlaps the `[s_rel, e_rel]` range is marked as part of the "core span" (`first_idx` to `last_idx`).
- **Rationale**: This eliminates the need for string matching at this stage, which is prone to failure with duplicate words or split phrases.

### Phase 3: Adaptive Viewport Centering
Once `first_idx` and `last_idx` are known, we select the window of words to return.
- **Algorithm**:
    1. `center_idx = floor((first_idx + last_idx) / 2)`
    2. `context_start = max(1, center_idx - half_limit)`
    3. `context_end = min(#words, center_idx + half_limit)`
    4. **Shift Left**: If `context_start > first_idx`, set `context_start = first_idx` and adjust `context_end`.
    5. **Shift Right**: If `context_end < last_idx`, set `context_end = last_idx` and adjust `context_start`.
- **Rationale**: This ensures that even if the selection is off-center or very long, we prioritize keeping the highlighted words visible within the word limit.

## Debugging & Traceability
Add detailed print statements (prefixed with `[LLS]`) for:
- Trace Pivot distance for candidates.
- Detected Span (Word X to Y).
- Final Viewport (Word A to B).
