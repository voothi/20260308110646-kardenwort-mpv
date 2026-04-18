## Context

The highlight engine in `lls_core.lua` currently uses a 10-second fuzzy window to find matches for Anki records. While this ensures high recall, it causes "bleed" when the same phrase (e.g., "41 bis 45") appears multiple times in close proximity. Users need a way to restrict highlights to the exact occurrence they exported when Global mode is OFF.

## Goals / Non-Goals

**Goals:**
- Implement strict $(time, index)$ grounding for contiguous (Orange) highlights.
- Support phrase continuity across subtitle boundaries via origin-point verification.
- Maintain legacy support for un-anchored records using the existing context/fuzzy logic.

**Non-Goals:**
- Refactoring the entire Phase 3 (Split/Purple) matching engine.
- Changing the TSV schema (we use existing `time` and `idx` columns).

## Decisions

- **Decision 1: Origin-Point Traceback Logic**
  - **Rationale**: Phrases spanning segments (e.g. Sub A ends in "41 bis", Sub B starts with "45") have different start times. To verify grounding, we must trace back from the current word's `term_offset` to the `logical_idx` 1 in the phrase and check if THAT point matches the anchor.
  - **Alternatives**: Using unique GUIDs for every occurrence (too much overhead/breaking change).

- **Decision 2: Strict Rejection in Local Mode**
  - **Rationale**: If `anki_global_highlight` is false and a specific anchor exists, we should reject any match that doesn't align with that anchor, even if the context matches perfectly.
  - **Alternatives**: Relying solely on context matching (demonstrated to be too loose for repetitive texts).

## Risks / Trade-offs

- **Risk**: Small timing drifts (e.g. 50ms) could break grounding.
- **Mitigation**: Using a small 0.05s buffer when comparing `data.time` to `subs[].start_time` to account for floating point or timestamp inconsistencies.
