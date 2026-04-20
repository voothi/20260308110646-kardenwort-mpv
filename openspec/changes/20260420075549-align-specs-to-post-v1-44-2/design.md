## Context

The current `lls_core.lua` script (Post-v1.44.2 HEAD) implements a highly refined interaction and grounding engine. This design document formalizes the architectural decisions that govern Multi-Pivot Grounding, persistent selection sets, and the **Precision Neighborhood Verification** system.

## Goals / Non-Goals

**Goals:**
- Formalize **Precision Neighborhood Verification** (Token Intersection).
- Formalize the **Multi-Pivot Grounding** coordinate system (`LineOffset:WordIndex:TermPos`).
- Standardize the **Interaction Shield**, **Pointer Jump Sync**, and **Persistent Selection** logic.
- Codify the **Unified Punctuation Spacing Rule (UPSR)** for term reconstruction.

## Decisions

### 1. Precision Neighborhood Verification (Token Intersection)
To prevent "spurious highlights" in Global Mode, the engine scans neighboring segments (+/- 5 lines).
- **Match Requirement**: A highlight is only rendered if at least one meaningful word (length >= 2) from the neighborhood exists within the `data.__ctx_lower` (stored context).
- **Rationale**: Provides a "fuzzy anchor" that survives subtitle fragmentation while filtering common-word bleed.

### 2. Multi-Pivot Grounding Coordinates
Generates a coordinate map (`LineOffset:WordIndex:TermPos`) for every word in an export.
- **Rationale**: Ensures 100% unique scene-locking for identical terms by storing logical positions instead of geometric centers.

### 3. Interaction Shielding & Sync 
- **Shield**: 150ms temporal lock (`FSM.DW_MOUSE_LOCK_UNTIL`) filter hardware jitter.
- **Sync**: **Pointer Jump Sync** ensures hit-testing is recalculated immediately before action dispatch to prevent "latency drift".

### 4. Smart Joiner & Ellipses
- **UPSR**: Codifies spacing rules for punctuation (e.g., no space before `,`, `.`, and no space around `/`, `-`).
- **Ellipses**: Injects ` ... ` into `ctrl_pending_set` terms when gaps are detected (Adaptive Gap Detection).

## Risks / Trade-offs

- **Recall vs. Precision**: The 1-word intersection threshold is low to favor learners, but significantly improves precision over the legacy v1.2x literal matching.
- **Record Size**: Multi-Pivot coordinates increase TSV field complexity but are required for high-fidelity split-word highlighting.
