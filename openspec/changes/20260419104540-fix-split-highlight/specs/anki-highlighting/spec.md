## MODIFIED Requirements

### Requirement: Split-Phrase Temporal Memory
The identification engine must support split-term matching across subtitle segments with an extended temporal gap of up to 60.0 seconds (user-configurable).

#### Scenario: Complex Elliptical Dialogue
- **WHEN** A split-term card (e.g., "Hören ... sind") spans across multiple subtitle lines with long pauses between characters.
- **THEN** Both constituents MUST be highlighted with the split-term (purple) color if the gap is within the `anki_split_gap_limit`.

### Requirement: Multi-Pivot Grounding Precision
The highlight engine must prioritize absolute coordinate grounding (Line:Word:TermPos) for all selection types. If grounding data is present, the match MUST align with the specific scene metadata.

#### Scenario: Accurate Scene Locking
- **WHEN** Multiple identical words appear in an episode, but a card is grounded to a specific 1ms timestamp.
- **THEN** Only the intended occurrence MUST be highlighted when `anki_global_highlight` is disabled.

### Requirement: Hybrid Fallback Hierarchy
The identify engine MUST follow a strict fallback hierarchy:
1. **Anchored Match**: Highest priority. Verified against L:W:T coordinates.
2. **Shortest Span Fallback**: Secondary priority for split-terms. If no grounded match is found, the engine identifies the most likely sequence based on the shortest temporal span.
3. **Phase-Transition**: For contiguous range selections, if coordinate grounding fails, the engine SHALL fall back to a split-term match (Phase 2) to maintain visual persistence.
