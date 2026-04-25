## Why

This change formalizes the True Fuzzy Keyword Search introduced in Release v1.25.0. To reach professional-grade search utility, the engine was evolved from a simple sequential matcher to a **Tokenized Fuzzy Keyword Matcher** (inspired by `fzf`). This allows users to search for complex phrases using non-contiguous keywords in any order, providing a significantly higher degree of "forgiveness" for typos and word-order swaps during intensive immersion.

## What Changes

- Implementation of **Tokenized Fuzzy Logic**: The search query is now split into whitespace-separated tokens. Each token is validated independently as either a literal substring or a fuzzy subsequence.
- Implementation of **Order-Independent Matching**: Keywords can appear in any order within the target subtitle (e.g., "fox quick" will correctly match "The Quick Brown Fox").
- Introduction of a **Multi-Dimensional Scoring** engine:
    - **Base (500)**: All keywords identified in the string.
    - **Literal Bonus (+100 per token)**: Rewards exact character sequences.
    - **Sequential Bonus (+300)**: Rewards keywords appearing in their natural text order.
    - **Proximity/Substring Bonus (+400)**: Rewards exact literal phrase matches.
    - **Start-of-Line Bonus (+300)**: Prioritizes sentences starting with the primary keyword.
- Optimization of the matching loop with early-exit guards for unmatched tokens.

## Capabilities

### New Capabilities
- `tokenized-fuzzy-search`: A sophisticated search capability that handles multi-keyword queries with order independence and approximate matching.
- `multi-dimensional-relevance-scoring`: An advanced ranking system that uses multiple linguistic signals (order, proximity, positioning) to determine result priority.

### Modified Capabilities
- `universal-subtitle-search`: Significantly evolved with modern interactive search logic.

## Impact

- **Search Flexibility**: Users no longer need to remember exact word order or spellings to find specific dialogue.
- **Result Quality**: High-signal matches (like literal phrases) are algorithmically pushed to the top of the search HUD.
- **Workflow Speed**: Faster lookup times due to the "fzf-like" mental model where typing a few fragments of a phrase is sufficient for discovery.
