## Why

The recent performance optimizations (three-tiered caching, hoisting, and binary search indexing) have significantly reduced CPU load but introduced subtle UX "stale state" regressions. Specifically, toggling certain modes (Drum Mode, Global Highlights) does not immediately refresh the OSD because the high-level draw caches are not invalidated. Additionally, the lack of configuration-aware cache flushing and the presence of dead hit-zone code in the Drum Window logic pose risks to consistency and maintainability.

## What Changes

- **Cache Invalidation for Toggles**: Integrate `flush_rendering_caches()` into `cmd_toggle_drum` and `cmd_toggle_anki_global` to ensure immediate UI feedback.
- **Robust Draw Cache Sentinels**: Add `is_drum` (or equivalent mode prefix) as a sentinel field in `DRUM_DRAW_CACHE` to detect mode transitions.
- **Configuration-Aware Flushing**: Register a property observer for the `script-opts` namespace to increment `LAYOUT_VERSION` whenever runtime options are updated.
- **Dead Code Removal**: Delete orphaned `DW_HIT_ZONES` caching/restoration logic in `draw_dw` which currently refers to a non-existent state field.
- **Interaction Shielding Refinement**: Ensure the 50ms pointer jump shield is consistently respected across all interactive OSD layers.

## Capabilities

### New Capabilities
- `cache-hardening`: Implements a unified invalidation strategy that links UI state toggles, configuration changes, and data updates to the rendering cache versions.

### Modified Capabilities
- `drum-window-performance`: Requirements for cache validity are being tightened to include mode and configuration state.

## Impact

- `scripts/lls_core.lua`: Modification of `draw_dw`, `draw_drum`, `flush_rendering_caches`, and toggle commands.
- `mpv` OSD responsiveness: Improved synchronization between user actions and visual output.
