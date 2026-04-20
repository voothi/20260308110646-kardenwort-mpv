## 1. Unified Fallbacks and Constants

- [x] 1.1 Update `calculate_highlight_stack` fallbacks: `safety_limit` (35), `scan_padding` (35), `gap_limit` (60.0) to align with `Options` defaults.
- [x] 1.2 Refactor `get_relative_word_text` to accept a `max_gap` parameter to allow for role-specific temporal grounding.

## 2. Shared Context Buffer Optimization

- [x] 2.1 Implement persistent `ctx_list` construction logic in `calculate_highlight_stack` that fires only once per unique `sub_idx`.
- [x] 2.2 Update Phase 3 search loop to traverse the pre-built `ctx_list` instead of performing redundant tokenization.

## 3. Strict Contiguous Grounding

- [x] 3.1 Enforce a strict 1.5s `max_gap` in `get_relative_word_text` when evaluating Phase 1 (Contiguous) phrases.
- [x] 3.2 Verify that Phase 3 (Split matching) maintains compliance with the 60.0s conversational gap.

## 4. Local Mode Gated Healing

- [x] 4.1 Update Phase 2 Local Mode grounding to trigger a "healing check" if the primary pivot index fails.
- [x] 4.2 Implement +/- 1 line segment scanning within the healing logic to re-locate the target word body.
- [x] 4.3 Ensure the healing pass validates the recovered anchor against the card's `__ctx_lower` using the Robust Neighbor Verification pass.
