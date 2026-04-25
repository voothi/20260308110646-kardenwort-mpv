## Why

This change formalizes the Search Relevance & Cyrillic Parity features introduced in Release v1.24.10. Initial search implementations suffered from a "chronological bias" where matches were presented in the order they appeared in the subtitle file, regardless of their relevance to the user's query. This update introduces a sophisticated scoring engine to prioritize exact and prefix matches. Additionally, it addresses a core Lua limitation regarding non-ASCII character normalization, ensuring that Cyrillic searches are truly case-insensitive.

## What Changes

- Implementation of a **Relevance Scoring Engine**: Potential matches are now weighted based on quality:
    - **Exact Match** (case-insensitive): 1000 points.
    - **Prefix Match**: 800 points.
    - **Substring Match**: 500 points.
    - **Fuzzy/Subsequence Match**: 100 points.
- Implementation of **Relevance-Based Sorting**: Search results are now sorted using a `Score DESC, Index ASC` strategy, ensuring high-quality matches appear first while preserving chronological order for identical scores.
- Introduction of **Cyrillic Case Mapping**: A new `utf8_to_lower(str)` utility that correctly normalizes Russian upper/lower case character pairs, bypassing Lua's ASCII-only `string.lower` limitation.
- Performance optimization ensuring the sorting engine remains well within the 50ms tick budget for large subtitle files.

## Capabilities

### New Capabilities
- `search-relevance-scoring`: A weighted ranking system that identifies and prioritizes the most likely user intent within search results.
- `cyrillic-case-normalization`: A specialized UTF-8 text processing capability for handling the complexities of Russian character sets in a typically ASCII-centric environment.

### Modified Capabilities
- `universal-subtitle-search`: Upgraded with significantly more intelligent result ordering and multi-language robustness.

## Impact

- **Search Accuracy**: The most relevant results are now visually prioritized at the top of the search HUD.
- **Linguistic Precision**: Elimination of "missed records" in Russian subtitles due to capitalization mismatches.
- **User Satisfaction**: A search experience that feels more modern and intuitive, matching the behavior of standard desktop search tools.
