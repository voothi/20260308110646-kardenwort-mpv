## Why

Achieve 100% precise, flicker-free highlighting for all subtitle selections (Word, Phrase, and Multi-line Range) in the Drum Window (Mode W). Legacy regex-based matching and single-word anchoring caused "highlight bleed" (incorrectly highlighting different scenes with identical words) and recurring failures for large multi-line blocks.

## What Changes

- **Multi-Pivot Grounding**: Transitioned from single-index anchoring to a comprehensive coordinate system (`LineOffset:WordIndex:TermPos`) for every word in a selection.
- **Temporal Epsilon**: Implemented a mandatory +1ms offset in all Anki exports to ensure anchoring coordinates always land safely within the intended subtitle segment, eliminating boundary drift.
- **Configurable Tolerances**: Moved all hardcoded search windows, gap limits, and neighbor-check thresholds to user-configurable variables in `mpv.conf`.
- **Phase 1 (Contiguous) Identification Overhaul**: Refactored the Orange highlight engine to trust multi-pivot grounding as "Ground Truth," allowing large chunks to be correctly identified without fragile fuzzy context checks.
- **Optimization**: Implemented recursive result caching and "lazy-parsing" for grounded maps to maintain performance during playback and scrolling.

## Capabilities

### New Capabilities
- **Precision Grounding**: Stable, scene-locked highlighting that persists across different episodes and identical word occurrences.

### Modified Capabilities
- `anki-highlighting`: Replaced all legacy regex-based pathfinding with strict coordinate-driven mapping. Enforced "Anki Global" toggle compatibility at the core engine level.

## Impact

- **Core Script**: `scripts/lls_core.lua` refactored for Multi-Pivot logic.
- **Configuration**: Added 4 new tunable parameters to `mpv.conf`.
- **UX**: Flicker-free, orange-priority highlighting for large range selections.
