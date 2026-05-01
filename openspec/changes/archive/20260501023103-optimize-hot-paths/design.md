## Context

`lls_core.lua` is a 6,164-line monolithic Lua script for mpv that provides Drum Mode, Drum Window, Anki highlighting, and subtitle interactivity. It runs a `master_tick()` loop at 50ms intervals. Performance profiling identified four hot-path optimization opportunities. All changes are internal to this single file and purely additive (caching layers and constant hoisting). No behavioral changes.

## Goals / Non-Goals

**Goals:**
- Reduce redundant ASS string generation in Drum Mode via a result cache
- Replace O(H) linear highlight scanning with O(log H + W) time-bucketed lookups
- Eliminate per-call allocation overhead in `utf8_to_lower()`
- Ensure cache coherence between `__split_valid_indices` and TSV reloads

**Non-Goals:**
- Changing the tick rate (50ms is appropriate)
- Modifying rendering logic, export behavior, or selection mechanics
- Adding user-facing configuration options
- Optimizing the proportional font width heuristic (monospace is the default)

## Decisions

### Decision 1: Drum Mode Draw Cache — Mirror the DW pattern

**Choice**: Add a `DRUM_DRAW_CACHE` table identical in structure to the existing `DW_DRAW_CACHE`.

**Cache key fields**: `center_idx`, `time_pos` (floored to 50ms buckets), `selection state` (anchor/cursor line+word), `pending_version`, `ANKI_HIGHLIGHTS` length.

**Invalidation**: Any key field change triggers a full rebuild. This is identical to how `DW_DRAW_CACHE` works at L3052–3057.

**Why not time-based TTL?** The tick loop already runs at fixed 50ms intervals. State-based invalidation is simpler and more reliable than time-based expiry.

**Location**: New table `DRUM_DRAW_CACHE` near L2806, checked at the top of `draw_drum()`.

### Decision 2: Time-Bucketed Highlight Index

**Choice**: When `load_anki_tsv()` builds `FSM.ANKI_HIGHLIGHTS`, also build a sorted-by-time index `FSM.ANKI_HIGHLIGHTS_SORTED`. In `calculate_highlight_stack()`, use binary search to find the window `[sub_start - window, sub_end + window]` instead of scanning all H entries.

**Structure**:
```
FSM.ANKI_HIGHLIGHTS_SORTED = {
    { time = 1.234, idx = 1 },
    { time = 5.678, idx = 2 },
    ...
}
-- Sorted by .time ascending
```

**Lookup**: Binary search for the first entry where `time >= sub_start - window`, linear scan until `time > sub_end + window`. This is O(log H + W) where W is the number of highlights in the window.

**Global Mode fallback**: When `anki_global_highlight = true`, skip the index and fall back to the existing linear scan (all highlights are eligible).

**Why not a hash map?** Time ranges are continuous, not discrete. A sorted array with binary search is the natural structure for range queries.

### Decision 3: Hoist `utf8_to_lower` Tables to Module Scope

**Choice**: Move the `upper` and `lower` Cyrillic strings and their `utf8_to_table()` results to module-scope constants, created once at script load.

**Before** (inside function, per-call):
```lua
local upper = "АБВГДЕЁЖЗИЙКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯ..."
local lower = "абвгдеёжзийклмнопрстуфхцчшщъыьэюя..."
local u_table = utf8_to_table(upper)
local l_table = utf8_to_table(lower)
```

**After** (module scope, once):
```lua
local CYRILLIC_UPPER = utf8_to_table("АБВГДЕЁЖЗИЙКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯÄÖÜẞ")
local CYRILLIC_LOWER = utf8_to_table("абвгдеёжзийклмнопрстуфхцчшщъыьэюяäöüß")
```

The function body simply references the module-scope constants.

### Decision 4: Clear `__split_valid_indices` on TSV Reload

**Choice**: At the end of `load_anki_tsv()`, after replacing `FSM.ANKI_HIGHLIGHTS`, iterate through `Tracks.pri.subs` and `Tracks.sec.subs` and set `sub.__split_valid_indices = nil` for each subtitle.

**Why not clear lazily?** The split-match cache is keyed by `term_key`, and after a TSV reload the set of terms may have changed. Lazy invalidation would require tracking which terms were added/removed, which is more complex than a simple flush.

**Performance of the flush**: O(N) where N is the number of loaded subtitles. For a typical 2-hour video with ~3000 subtitles, this is a trivial loop that runs at most once every `anki_sync_period` seconds (default: 5s) and only when the TSV file actually changed.

## Risks / Trade-offs

- **[Drum draw cache staleness]** → Mitigated by including `#FSM.ANKI_HIGHLIGHTS` in the cache key, so any highlight addition/removal invalidates. Also invalidated by selection state changes and `DW_CTRL_PENDING_VERSION`.

- **[Time-index maintenance cost]** → Mitigated by building the index only during `load_anki_tsv()`, not on every tick. The sort is O(H log H) but runs at most once every 5 seconds, and only when the file actually changed.

- **[Split cache flush on false-positive file change]** → If an external process touches the TSV mtime without changing content, the flush runs unnecessarily. Cost is negligible (O(N) nil assignment).

- **[Global Mode still linear]** → By design. Global Mode disables the time-window filter, so all highlights must be evaluated. The time-index optimization does not apply here. This is documented in the proposal as a known architectural limitation.
