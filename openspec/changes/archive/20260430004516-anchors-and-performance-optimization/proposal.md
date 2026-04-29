## Why

The current subtitle capture system relies on word-level granularity, which can cause inconsistencies when handling character-specific punctuation or split-phrase "anchors" across multiple lines. Additionally, the recent introduction of the unified global semantic pass has increased CPU overhead, necessitating a performance hardening layer to ensure smooth UI responsiveness as the Anki highlight database grows.

## What Changes

- **Precision Anchoring**: Transition from word-index anchoring to character-offset anchoring for high-fidelity split-phrase capture.
- **Highlight Database Indexing**: Implementation of a word-map index for the highlight database to transform linear $O(N)$ searches into $O(1)$ lookups.
- **OSD Result Caching**: High-level result caching for Drum Mode OSD (Primary and Secondary tracks) to skip redundant rendering cycles.
- **Layout & Tokenization Reuse**: Caching of wrapped token layouts on subtitle objects to minimize redundant wrapping and width calculations.
- **Redundancy Cleanup**: Optimization of the master tick loop to eliminate duplicate subtitle coordinate searches.

## Capabilities

### New Capabilities
- `performance-hardening`: Defines the requirements for result caching, layout reuse, and database indexing to maintain 60FPS UI performance.

### Modified Capabilities
- `anki-highlighting`: Updates requirements to support character-offset precision for non-contiguous (paired) phrase preservation.

## Impact

The changes primarily affect `lls_core.lua`, specifically the `master_tick`, `draw_drum`, and `calculate_highlight_stack` functions. The Anki TSV loading logic is also modified to support the new indexing structure.
