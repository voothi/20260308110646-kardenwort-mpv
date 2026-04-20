## Why

The highlighting engine currently suffers from performance bottlenecks in Phase 3 (split phrase detection) due to redundant tokenization. Furthermore, it exhibits inconsistent temporal grounding between contiguous and non-contiguous matches, and local mode highlight persistence is brittle to minor subtitle file edits, causing unnecessary highlight loss.

## What Changes

- **Shared Context Buffer**: Optimization of the split-phrase matching loop to use a shared `ctx_list` per refresh cycle.
- **Temporal Gap Bifurcation**: Enforcement of a strict 1.5s gap for contiguous segment-bridging matches, while preserving the 60s limit for non-contiguous split terms.
- **Gated Fuzzy Healing**: Implementation of a resilient anchoring fallback for Local Mode that allows minor index drift while preventing incorrect matches.
- **Fallback Unification**: Elimination of hardcoded magic numbers in favor of unified `Options` defaults.

## Capabilities

### New Capabilities
- None

### Modified Capabilities
- `anki-highlighting`: Relaxes split-search centering and updates grounding enforcement rules.
- `high-recall-highlighting`: Formalizes the 1.5s temporal threshold for contiguous inter-segment phrase integrity.

## Impact

Affects the core highlighting logic in `scripts/lls_core.lua` (specifically `calculate_highlight_stack`). Improves rendering performance for users with large Anki collections and increases the reliability of "Ground Truth" highlighting.
