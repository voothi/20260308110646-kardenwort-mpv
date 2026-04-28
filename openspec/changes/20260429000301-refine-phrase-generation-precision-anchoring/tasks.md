# Tasks: Refine Phrase Generation

## Phase 1: Robust Anchoring
- [x] Add `if word ~= "..." then` check to the non-contiguous fallback loop in `extract_anki_context`.
- [x] Add candidate match distance logging for easier debugging of pivot selection.

## Phase 2: Precision Truncation
- [x] Calculate `s_rel` and `e_rel` relative to the sentence start.
- [x] Implement the character-to-word mapping loop to find `first_idx` and `last_idx`.
- [x] Replace the existing `target_idx` search loop in the truncation section.

## Phase 3: Adaptive Viewport
- [x] Implement the `center_idx` calculation.
- [x] Implement the shifting logic to ensure `first_idx` and `last_idx` are included.
- [x] Add viewport trace logging (`[LLS] Viewport: X to Y`).

## Phase 4: Verification
- [ ] Test with a non-contiguous selection across a long sentence to verify no words are cut off.
- [ ] Verify that the word limit is still respected.
