## Context

The current `lls_core.lua` script (Post-v1.44.2 HEAD) implements a highly refined interaction and grounding engine. This design document formalizes the architectural decisions that govern Multi-Pivot Grounding, persistent selection sets, and the new **Precision Neighborhood Verification** system. These features ensure that even "Global" highlights remain accurately anchored to their original linguistic context.

## Goals / Non-Goals

**Goals:**
- Formalize **Precision Neighborhood Verification** (Word-Token Intersection).
- Formalize the **Multi-Pivot Grounding** coordinate system (`LineOffset:WordIndex:TermPos`).
- Standardize the **Interaction Shield** and **Persistent Selection** logic for remote-resilient input.

**Non-Goals:**
- This design document does not propose changes to the code; it documents the current state of `scripts/lls_core.lua`.

## Decisions

### 1. Precision Neighborhood Verification (Token Intersection)
To prevent "spurious highlights" when `anki_global_highlight` is enabled, the system now performs a context-proximity check.
- **Mechanism**: The engine scans neighboring subtitle segments (+/- `anki_neighbor_window`). It tokenizes these segments and identifies meaningful words (length >= 2, stripped of punctuation).
- **Match Requirement**: A highlight is only rendered if at least one meaningful word from the neighborhood exists within the `data.__ctx_lower` (the stored context of the Anki card).
- **Rationale**: This provides a "fuzzy anchor" that prevents common words (like "und" or "ich") from being highlighted in irrelevant scenes, while still allowing for natural variations in subtitle timing or layout.

### 2. Multi-Pivot Grounding Coordinates
To eliminate "highlight bleed" for local selections, the system generates a coordinate map for every word in a selection. 
- **Format**: `LineOffset:WordIndex:TermPos` (e.g., `0:4:1`).
- **Rationale**: Unique scene-locking for identical terms.

### 3. Interaction Shielding (150ms)
Filter hardware jitter (JoyToKey/8BitDo) by setting `FSM.DW_MOUSE_LOCK_UNTIL = current_time + 150ms` upon any keyboard/remote command.

### 4. Persistent Selection State
`FSM.DW_CTRL_PENDING_SET` persists across modifier-key releases to support minimalist input devices (remote controls) that lack "hold" modifier ergonomics.

## Risks / Trade-offs

- **Fuzzy Recall Risk**: The 1-word intersection threshold is intentionally low to maximize recall for language learners, but it could still technically misfire in extremely sparse subtitle environments. However, this is a significant improvement over literal string matching.
- **Coordinate String Length**: Multi-Pivot coordinates increase the size of the `SentenceSourceIndex` field in Anki, but the precision gain for split-word highlighting is worth the storage cost.
