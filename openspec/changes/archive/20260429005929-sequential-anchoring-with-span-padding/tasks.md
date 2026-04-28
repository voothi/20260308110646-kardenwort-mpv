# Tasks: Implement Sequential Anchoring

## Phase 1: Robust Anchoring
- [x] Implement Sequential Forward Search in the non-contiguous fallback loop.
- [x] Ensure the first word anchors to the pivot while subsequent words search strictly forward.

## Phase 2: Offset Correction
- [x] Calculate `sentence_abs_start` by detecting leading-character stripping during sentence cleaning.
- [x] Use `sentence_abs_start` to derive `s_rel` and `e_rel` for word mapping.

## Phase 3: Adaptive Truncation
- [x] Implement wide-span handling (short-circuiting centered windowing when span >= limit).
- [x] Add fixed padding around the span for wide selections.

## Phase 4: Configuration
- [x] Add `anki_context_span_pad` to `lls_core.lua` options.
- [x] Expose `lls-anki_context_span_pad` in `mpv.conf` with appropriate comments.

## Phase 5: Verification
- [x] Verify sequential anchoring with the "bag six" vs "six five four" edge case.
- [x] Verify span padding in TSV exports.
