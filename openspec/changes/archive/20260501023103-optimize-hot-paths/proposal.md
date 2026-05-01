## Why

The `master_tick` loop in `lls_core.lua` runs at 50ms intervals. Performance profiling revealed four optimization opportunities: Drum Mode lacks a draw cache (unlike the DW which has `DW_DRAW_CACHE`), the Anki highlight matcher scans all highlights linearly for every token, the `utf8_to_lower` function re-creates Cyrillic case-mapping tables on every call, and stale split-match caches persist after external TSV reloads.

## What Changes

- **Add Drum Mode draw cache**: Introduce a result cache (like `DW_DRAW_CACHE`) for `draw_drum()` to skip redundant ASS string generation when the active subtitle, selection state, and highlight version haven't changed.
- **Add time-bucketed highlight index**: Replace the linear O(H) scan in `calculate_highlight_stack()` with a sorted-by-time structure that enables binary-search window lookups, reducing per-token cost from O(H) to O(log H + W).
- **Hoist `utf8_to_lower` case-mapping tables**: Move the Cyrillic upper/lower character arrays from inside `utf8_to_lower()` to module-scope constants, eliminating 68 temporary string allocations and 34 `gsub` replacements per call.
- **Clear stale `__split_valid_indices` on TSV reload**: When `load_anki_tsv()` replaces `FSM.ANKI_HIGHLIGHTS`, flush the `__split_valid_indices` cache on subtitle objects to prevent stale split-match results.

## Capabilities

### New Capabilities

- `drum-draw-cache`: Result-level caching for the `draw_drum()` renderer to skip redundant ASS generation.
- `highlight-time-index`: Time-bucketed indexing for Anki highlights to replace linear scanning with binary-search window lookups.

### Modified Capabilities

- `cyrillic-case-normalization`: Hoist internal character mapping tables to module scope for zero-allocation lowering.
- `drum-window-performance`: Extend cache invalidation to clear stale `__split_valid_indices` when the highlight database is reloaded.

## Impact

- **File**: `scripts/lls_core.lua` — all changes are internal to this single file.
- **Functions touched**: `draw_drum`, `tick_drum`, `calculate_highlight_stack`, `utf8_to_lower`, `load_anki_tsv`.
- **Risk**: Low — all changes are additive caching layers or table hoisting. No behavioral changes to rendering, export, or selection logic.
- **No breaking changes**.
