## Context

The current highlighter engine processes one subtitle segment at a time. This causes phrases that span two segments (e.g., "properly" at the end of Subtitle A and "configured" at the start of Subtitle B) to fail the sequence matching check, as the engine cannot "see" words outside the current segment.

## Goals / Non-Goals

**Goals:**
- Enable the matching engine to peek into adjacent subtitle segments.
- Maintain high precision by ensuring the temporal gap between segments is minimal (part of the same sentence).

**Non-Goals:**
- implementing a full multi-track cross-correlation (keep it simple within the primary track).

## Decisions

### 1. Context-Aware Subtitle Access
**Decision**: Update `calculate_highlight_stack` to accept the entire `subs` table and the current subtitle index, rather than just the word list of a single line.
**Rationale**: This allows the engine to resolve word indices that fall outside the current line's bounds by shifting to the previous or next entry in the `subs` buffer.
**Alternative**: Pre-calculating a flattened word list for the entire video. Rejecting because it's memory-intensive and breaks the per-subtitle rendering pipeline.

### 2. Segment Adjacency Check
**Decision**: Look across segment boundaries if the gap between `end_time` of Sub A and `start_time` of Sub B is less than 1.5 seconds.
**Rationale**: Accommodates natural speech pauses and scene transitions in news broadcasts.

### 3. Adaptive Temporal Window
**Decision**: Automatically extend the `anki_local_fuzzy_window` for long highlights (Word count > 10). Add 0.5 seconds per word to the detection window.
**Rationale**: Long paragraphs (e.g., news reports) take longer to read than the default 10s window allows. This prevents highlights from "flicking off" mid-read.

### 4. Semantic Self-Verification
**Decision**: In `anki_context_strict` mode, verify word neighbors against both the `SentenceSource` (context) and the `WordSource` (term) itself.
**Rationale**: Supports highlights that span multiple sentences where the user only captured the first sentence as context. Allows a phrase to "self-verify" its internal structure.

## Risks / Trade-offs

- [Risk] → Increased computational cost per word.
- [Mitigation] → We use a 1-level cache for `sub.words` to avoid re-parsing strings in the lookahead loop.

- [Risk] → Jumping too many segments could lead to false positives.
- [Mitigation] → Limited to 5 segments jump max, and strictly bound by the 1.5s adjacency rule.
