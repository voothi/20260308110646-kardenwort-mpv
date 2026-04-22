## Context

The original Context Copy logic in `copy_sub.lua` relied on a strict sequential check for duplicate lines, which failed in dual-track `.ass` files where English and Russian lines alternate. This caused karaoke fragments of the same sentence to be treated as separate dialogue blocks.

## Goals / Non-Goals

**Goals:**
- Bridge interleaved translations to correctly reassemble chronological sentences.
- Target specific languages for context collection based on user preference or script detection.

## Decisions

- **Deep Merge Buffer**: The array loading parser in `copy_sub.lua` now searches up to 10 entries backwards to find matches for merging. This window is sufficient to cover most interleaved translation scenarios.
- **Language Filtering**: `get_context_text` uses Cyrillic detection as a heuristic to identify and skip irrelevant tracks (e.g., skipping Russian translations when the target context is English).
- **Iterative Search**: The context search continues backwards and forwards until the requested number of unique sentences is satisfied.

## Risks / Trade-offs

- **Risk**: Searching 10 entries backwards might be slow on extremely large subtitle files.
- **Mitigation**: The search is limited to the immediate loading phase and the buffer size is small enough that performance impact is negligible.
- **Risk**: False positives in language detection.
- **Mitigation**: Focus on clear characteristic detection (like Cyrillic) which is highly reliable for the primary use cases.
