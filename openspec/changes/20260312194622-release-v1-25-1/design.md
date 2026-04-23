## Context

A query like `mne` would often match a subtitle like "**m**ake **n**ew **e**ntries" (Span: ~15) just as highly as a subtitle containing "**m**a**n**ag**e**" (Span: 6). From a user's perspective, the second match is much more likely to be the intended target. This release implements the math to distinguish between these cases.

## Goals / Non-Goals

**Goals:**
- Identify the physical "width" of a fuzzy match.
- Favor results where the match span is small relative to the query length.
- Maintain the performance levels achieved in previous search releases.

## Decisions

- **Span Indexing**: `find_fuzzy_span` is implemented to capture the first and last indices of a successful subsequence match. This allows the scoring engine to calculate the "character density" of the match.
- **Bonus Calculation**:
    - The engine calculates a "Compactness Ratio" (Match Length / Span).
    - If the span is very narrow (near 1:1), an **Ultra-Compact Bonus** is applied.
    - This bonus is high enough (+150) to push intra-word matches above inter-word matches, but low enough not to override exact literal phrase bonuses (+400).
- **Algorithm Optimization**: The span finder remains a single-pass O(N) loop to ensure zero lag during real-time filtering of large subtitle files.

## Risks / Trade-offs

- **Risk**: A very long line might contain a compact match late in the text.
- **Mitigation**: The system already uses a "Sequential Order Bonus" (+300) and an "Index-based Sort" to balance chronological order with match quality.
