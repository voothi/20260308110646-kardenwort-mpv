## Why

The current Anki context extraction engine uses geometric midpoint proximity to resolve ambiguous term occurrences when multiple instances of a word exist in the context window. This leads to "research drift" and context bleed, where the wrong occurrence is highlighted or extracted. We need to transition to precise logical anchoring using the Multi-Pivot grounding maps that the system already generates during export.

## What Changes

- **Logical Anchoring Integration**: Refactor the context extraction engine to ingest and prioritize the `advanced_index` (Multi-Pivot map) for word localization.
- **Geometric Fallback Deprecation**: Remove geometric midpoint calculations for all records where logical grounding data is available.
- **Export Flow Synchronization**: Update the Drum Window export handler to pass the logical coordinate string directly to the mapping resolver.

## Capabilities

### New Capabilities
- None

### Modified Capabilities
- `drum-window-indexing`: Refine the Marker-Injection requirement to mandate the use of logical coordinate maps for context extraction, replacing geometric proximity matching.

## Impact

- **Affected Code**: `scripts/lls_core.lua` (specifically `extract_anki_context` and `dw_anki_export_selection`).
- **Data Integrity**: Increased reliability for Anki records containing common or repeated terms in a single subtitle segment.
