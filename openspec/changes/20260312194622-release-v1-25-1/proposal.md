## Why

This change formalizes the Compact Proximity Search features introduced in Release v1.25.1. While the tokenized fuzzy search (v1.25.0) significantly improved search flexibility, it introduced a new issue: "false positive" matches where the search characters were scattered distantly across a long subtitle line. This update introduces proximity-aware scoring to prioritize results where the fuzzy match is concentrated within a single word or a narrow span of text, greatly increasing the perceived intelligence of the search engine.

## What Changes

- Implementation of **Match Span Calculation**: The `is_fuzzy_subsequence` utility has been upgraded to `find_fuzzy_span()`, which returns the exact start and end indices of the matched sequence.
- Introduction of **Compactness Bonuses**:
    - **Ultra-Compact (+150)**: Awarded when the match span is almost equal to the query length (indicating an intra-word or very localized match).
    - **Compact (+50)**: Awarded for matches that are slightly wider but still localized within a small neighborhood of characters.
- Integration of span calculation into the existing multi-dimensional scoring engine to refine the final result ranking.
- Performance optimization: The `find_fuzzy_span` logic remains O(N), ensuring real-time responsiveness during typing.

## Capabilities

### New Capabilities
- `fuzzy-span-calculation`: A text processing capability that identifies the exact positional boundaries of a fuzzy match within a string.
- `proximity-based-relevance`: A ranking logic that rewards high-density matches, distinguishing between concentrated intent and accidental character matches.

### Modified Capabilities
- `tokenized-fuzzy-search`: Upgraded with superior proximity-aware scoring.

## Impact

- **Signal-to-Noise Improvement**: Highly localized matches are visually prioritized over "scattered" matches.
- **Improved Typo Handling**: Finding a misspelled word is now more reliable as the engine favors the compact (intra-word) match over accidental matches across the line.
- **Search Professionalism**: The HUD results feel more precise and intuitive, matching the behavior of high-end developer tools.
