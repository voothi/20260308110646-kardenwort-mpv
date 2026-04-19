## Context

The split-term highlight engine in the Drum Window identifies non-contiguous phrases (e.g., "Hören ... sind"). Currently, it uses a 5-second per-subtitle gap limit and a narrow 3-line search window. Additionally, it strictly enforces the `SentenceSourceIndex` anchor, which causes matching failures if the TSV index is inaccurate.

## Goals / Non-Goals

**Goals:**
- Ensure elliptical phrases correctly highlight across multi-subtitle boundaries.
- Support "Best Effort" highlighting for unanchored or inaccurately indexed split-terms.
- Fix TSV export grounding for multi-select paired terms.

**Non-Goals:**
- Modifying contiguous (orange) highlight logic (already stable).
- Changing the manual selection UI.

## Decisions

- **Temporal Expansion**: Increase `gap` tolerance to 12.0s and `s_start/s_end` scan to +/- 10 lines in `calculate_highlight_stack`.
- **Search Fallback**: Introduce `best_unanchored_tuple` in the split-term coordinate search. If no anchored sequence matches, use the shortest-span unanchored sequence found in the context.
- **Robust Ellipsis matching**: Update `find` criteria to match `...` without whitespace padding requirements.
- **Export Fix**: Update `ctrl_commit_set` to correctly propogate `members[1].word` as the grounding index.

## Risks / Trade-offs

- **Highlight Bleed**: Allowing unanchored matches increases the risk of highlighting the wrong occurrence if words are repeated in the context window. However, elliptical phrases are usually sufficiently unique that "shortest span" logic effectively mitigates this.
