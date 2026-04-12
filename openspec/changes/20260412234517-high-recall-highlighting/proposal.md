## Why

The original exact-phrase highlighter was too rigid for the fragmented subtitles found in real-world news broadcasts. It failed when phrases were split across subtitles, when long paragraphs exceeded the 10-second fuzzy window, or when speech pauses interrupted segments. Conversely, Global Mode suffered from "false positives" (e.g., matching the word "nur" from a long saved paragraph in unrelated contexts).

## What Changes

- **Adaptive Semantic Highlighter**: Refactored the engine to handle huge blocks of text (news reports) with intelligent neighbor-aware verification.
- **Windowed Sequence Matching**: Verifies ±3 word neighborhoods to ensure phrase integrity while allowing for fragmented display buffers.
- **Temporal Resilience**: Implemented dynamic window scaling (+0.5s per word) and relaxed 1.5s adjacency rules.
- **High-Performance Caching**: Added lazy-caching for cleaned word lists to maintain 0-latency UI responsiveness during heavy rendering.

## Capabilities

### New Capabilities
- `high-recall-highlighting`: Advanced highlighter engine with semantic set matching, adaptive temporal windows, and high-performance segment peeking.

### Modified Capabilities
- `anki-highlighting`: Update requirements to support multi-segment phrases and adaptive windows.

## Impact

- `lls_core.lua`: Deep refactor of `calculate_highlight_stack` and the subtitle rendering loop.
- UI: Restoration of snappy mouse interaction through pre-caching.
