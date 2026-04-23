## Context

The previous search was limited to sequential matching, which made finding multi-word phrases difficult if the user couldn't remember the exact starting word. This release adopts the "keyword fragments" philosophy used in modern development tools like `fzf` or IDE file-searchers.

## Goals / Non-Goals

**Goals:**
- Support multi-keyword queries with arbitrary order.
- Provide a robust scoring system that favors high-signal matches.
- Maintain typo-tolerance via per-token fuzzy logic.

## Decisions

- **Tokenization Strategy**: Queries are split into a table of tokens. The search function iterates through each token and ensures it satisfies a fuzzy match against the target string. If any token fails to match, the line is discarded (logical AND).
- **Composite Scoring**: The final score is no longer a single tier. It is built by accumulating bonuses based on:
    - How many tokens matched literally (+100 each).
    - If tokens appeared in the same order as the source text (+300).
    - If the tokens combined form an exact substring (+400).
    - If the first token appears at the start of the line (+300).
- **Optimization**: To handle large files, the system uses an early-exit guard. Once a token is found to be missing from a subtitle, the rest of the scoring logic for that line is skipped.

## Risks / Trade-offs

- **Risk**: Increased CPU usage due to nested loops.
- **Mitigation**: The algorithm is highly optimized and remains well within the 50ms tick budget for standard movie-length subtitle files.
