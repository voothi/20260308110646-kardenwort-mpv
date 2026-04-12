## Context

The highlighter must function reliably during fast-paced news broadcasts where subtitles are aggressively fragmented. The previous model failed on long paragraphs (>10s duration) and segments separated by more than 500ms.

## Goals / Non-Goals

**Goals:**
- Zero-latency UI interaction by offloading text processing from the render loop.
- Continuity for multi-subtitle highlights spanning up to 5 segments.
- Precision filtering for common words in Global Mode.

**Non-Goals:**
- Full cross-correlation with translations (staying within the primary track).

## Decisions

### 1. Lazy Pre-Caching
**Decision**: Pre-clean and cache the word list and lower-case term on first access.
**Rationale**: Avoids redundant `utf8_to_lower` and `gsub` calls for every word on screen (20 words * 100 terms = 2,000 calls per frame). Restores instantaneous mouse responsiveness.

### 2. Adaptive Temporal Window
**Decision**: Linearly scale the `fuzzy_window` for long highlights: `window = base + (word_count * 0.5)`.
**Rationale**: 10 seconds is mathematically insufficient for reading a 50-word paragraph. Scaling ensures the end of a report stays highlighted while the start is still fresh.

### 3. Windowed Sequence Matching
**Decision**: Verify only a ±3 word local "neighborhood" around the match point.
**Rationale**: Verifying a full 50-word sequence fails when it exceeds the 5-subtitle display buffer. Checking local neighbors provides enough entropy to block common-word bleed while allowing long blocks to remain active across infinite length.

### 4. Segment Bridge Threshold
**Decision**: Increase segment adjacency from 500ms to 1.5s.
**Rationale**: Subtitle gaps in news broadcasts often reach 1s during breath pauses or scene transitions. 1.5s is safe for continuous speech.

## Risks / Trade-offs

- [Risk] → Memory usage increase for cached word lists.
- [Mitigation] → Only caches after the first hit. Clears on file/track change.

- [Risk] → False positives in extremely repetitive text.
- [Mitigation] → The ±3 word window (7 words total) is sufficient to uniquely identify almost any phrase in German news.
