## ADDED Requirements

### Requirement: Differentiated Contiguous vs Split Temporal Gaps
The highlighting engine SHALL enforce distinct temporal proximity thresholds for contiguous segment-bridging matches vs non-contiguous split terms.

#### Scenario: Strict contiguous bridging
- **WHEN** evaluating a phrase for a contiguous (Orange) highlight across subtitle boundaries
- **THEN** the temporal gap between segments MUST be less than or equal to 1.5 seconds.

#### Scenario: Permissive split-term spanning
- **WHEN** evaluating a phrase for a split-term (Purple) highlight (terms containing "...")
- **THEN** the temporal gap between segments SHALL be governed by the `anki_split_gap_limit` (default 60.0s).

### Requirement: Performance-Optimized Shared Scan Buffer
The engine SHALL generate a single, unified token scan buffer (`ctx_list`) for the entire evaluation window (+/- 35 lines) during a rendering cycle to eliminate redundant tokenization overhead.

#### Scenario: Massive Parallel Highlight Evaluation
- **WHEN** hundreds of multi-word Anki highlights are active
- **THEN** the system SHALL construct the `ctx_list` exactly once per sub-segment refresh across all Phase 3 matching operations.
