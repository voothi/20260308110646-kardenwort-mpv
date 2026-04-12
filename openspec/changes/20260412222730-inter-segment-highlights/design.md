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
**Decision**: Only look across segment boundaries if the gap between `end_time` of Sub A and `start_time` of Sub B is less than a small threshold (e.g., 500ms).
**Rationale**: This ensures we don't accidentally join words from unrelated scenes that happen to match a phrase.

## Risks / Trade-offs

- [Risk] → Increased computational cost per word.
- [Mitigation] → Peeking only occurs when a potential phrase match is detected at the boundary (start/end) of a line.

- [Risk] → `subs` table might not be loaded in all call sites.
- [Mitigation] → Provide a fallback to the old single-line logic if `subs` is missing.
