## Context

Users reported that searching for common words resulted in a "sea of results" where the most relevant matches were buried deep in the list. Furthermore, the search system was unable to find capitalized Russian words when the query was lowercase, creating significant friction during acquisition from literature or subtitles with sentence-case.

## Goals / Non-Goals

**Goals:**
- Prioritize exact and prefix matches at the top of the search HUD.
- Enable full case-insensitivity for Cyrillic characters.
- Maintain high performance (under 50ms) during result sorting.

## Decisions

- **Scoring Tiers**: A point-based system is implemented: 1000 (Exact), 800 (Prefix), 500 (Substring), 100 (Fuzzy). This provides enough separation to ensure clear visual hierarchy.
- **Stable-ish Sorting**: Using `table.sort` with a comparator that first checks `score` and then `index`. This ensures that for items with the same relevance score, their original chronological order is preserved.
- **Normalization Utility**: Since Lua's `string.lower` fails on multi-byte UTF-8, a `utf8_to_lower` function is created. It iterates through the string and replaces known Russian uppercase characters with their lowercase equivalents using a predefined mapping table.
- **Search Refresh**: The relevance logic is integrated directly into the `update_search_results` loop to minimize redundant data passes.

## Risks / Trade-offs

- **Risk**: Performance degradation on extremely large subtitle files (10,000+ lines).
- **Mitigation**: The sorting logic is only applied to the *matching* subset of subtitles, and the number of visible results is capped in the OSD.
