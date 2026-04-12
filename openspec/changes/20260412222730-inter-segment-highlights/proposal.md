## Why

Currently, the exact phrase matching engine is segment-bound. If a highlighted phrase (e.g., "falsch sind") is spread across two different subtitle blocks, the system fails to recognize the sequence, resulting in missing highlights. This change addresses this "edge case" which is actually common in news broadcasts and dialogue.

## What Changes

- **Inter-Segment Sequence Checking**: Refactor the highlighter matching engine to allow sequence verification to look into adjacent subtitle segments (previous/next).
- **Buffer-Aware Rendering**: Ensure that both the Drum and Drum Window modes provide the necessary subtitle buffer context to the matching engine.

## Capabilities

### New Capabilities
- `inter-segment-highlighter`: Capability to verify word sequences across subtitle segment boundaries by buffering adjacent subtitle text.

### Modified Capabilities
- `anki-highlighter`: Update the matching requirement to support multi-segment phrases without losing context strictness.

## Implementation Journey & Milestones

This change evolved through several critical field-testing milestones:

- **Precision vs. Recall (21:52:14)**: Transitioned to `Exact Phrase Matching` to stop common words like "Sie" from bleeding into unrelated contexts.
- **The Split Boundary (22:24:38)**: Discovered that "falsch sind" failed when split across segments; implemented the first inter-segment buffer.
- **Multi-Segment Peeking (22:43:00)**: Handling phrases that span 3+ tiny segments. Upgraded to recursive deep-peeking (5 segments max).
- **Semantic Set Scaling (22:46:32)**: Adapted the engine to handle huge paragraph-sized highlights (news reports) by allowing semantic word verification within the block.
- **Adaptive Temporal Windows (22:59:02)**: Implemented dynamic fuzzy window scaling (0.5s per word) to ensure long report highlights don't "flicker out" before the reader finishes.

## Impact

- `lls_core.lua`: Refactored `calculate_highlight_stack` into a high-performance, context-aware semantic matching engine.
- `mpv.conf`: Validated compatibility with local fuzzy window settings.
