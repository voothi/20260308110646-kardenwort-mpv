## Context

The `kardenwort-mpv` rendering pipeline uses three tiers of caching to maintain high performance. The current state relies on manual cache invalidation (`flush_rendering_caches()`), but several entry points (mode toggles and runtime configuration updates) currently bypass this mechanism, resulting in stale UI frames.

## Goals / Non-Goals

**Goals:**
- Sync `DRUM_DRAW_CACHE` and `DW_DRAW_CACHE` with all relevant state toggles.
- Implement configuration-triggered invalidation using `mp.observe_property`.
- Clean up the `DW_HIT_ZONES` dead code to maintain architectural clarity.

**Non-Goals:**
- Adding new rendering features or changing visual styles.
- Refactoring the core layout logic beyond the caching sentinels.

## Decisions

### 1. Mode Sentinels in High-Level Caches
Both `DRUM_DRAW_CACHE` and `DW_DRAW_CACHE` will be extended to include mode-specific sentinels.
- **Decision**: Add `is_drum` to `DRUM_DRAW_CACHE`.
- **Rationale**: Currently, `draw_drum` can be called in both Drum and SRT modes. Without this sentinel, the cache might return a Drum-styled string when the user has just toggled to SRT mode.

### 2. Global Option Observers
The script currently reads options once at load time or during specific events.
- **Decision**: Register `mp.observe_property("script-opts", "string", ...)` to call `flush_rendering_caches()`.
- **Rationale**: This allows the user to change font sizes, colors, and gaps at runtime via `mpv.conf` or `script-message` without requiring a script reload or a playback event to clear stale layouts.

### 3. Integrated Toggle Invalidation
Toggle commands are currently "fire and forget" regarding the OSD state.
- **Decision**: Call `flush_rendering_caches()` inside `cmd_toggle_drum` and `cmd_toggle_anki_global`.
- **Rationale**: This ensures that the next `master_tick` or manual OSD update sees a mismatched version and rebuilds the frame with the new settings.

## Risks / Trade-offs

- **[Risk]** Excessive cache flushing on config updates → **[Mitigation]** `mp.observe_property` for `script-opts` is only triggered when values actually change, and the flush itself is a simple O(1) version increment.
- **[Trade-off]** Memory usage for sentinels → **[Mitigation]** The overhead of storing a few extra booleans/numbers in the cache table is negligible compared to the robustness gained.
