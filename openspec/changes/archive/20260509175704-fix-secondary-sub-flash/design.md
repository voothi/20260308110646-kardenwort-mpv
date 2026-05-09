## Context

Mpv property updates and script observers are processed in the event loop. When a script changes a property that affects subtitle visibility (like `secondary-sid`), there can be a delay between the property being set and the script's periodic tick or observer enforcing the desired visibility state (suppressed for OSD). This delay manifests as a visual flash of native subtitles.

The current implementation relies on `master_tick` (every 50ms) to enforce suppression:
```lua
if dw_active or pri_use_osd or sec_use_osd then
    -- ...
    if mp.get_property_bool("secondary-sub-visibility") ~= target_sec_vis then
        mp.set_property_bool("secondary-sub-visibility", target_sec_vis)
    end
end
```
If `cmd_cycle_sec_sid` runs right after a tick, there is a ~50ms window where native subtitles may be visible.

## Goals / Non-Goals

**Goals:**
- Eliminate flickering of native secondary subtitles during track switching.
- Ensure OSD updates are perceived as instantaneous and seamless.
- Maintain consistent state between `FSM.native_sec_sub_vis` and `secondary-sub-visibility`.

**Non-Goals:**
- Modifying mpv core behavior.
- Re-architecting the entire `master_tick` loop.

## Decisions

### 1. Synchronous Suppression in Call-Site
In `cmd_cycle_sec_sid`, we will immediately set `secondary-sub-visibility` to `false` if OSD mode is active. This closes the window before the `secondary-sid` change is processed by mpv's renderer.

### 2. Hardened Observer
Add suppression logic inside the `secondary-sid` observer. This ensures that even if the track is changed via external means (native mpv keys), the native subs are hidden before the next OSD render cycle.

### 3. Immediate OSD Redraw
Call `drum_osd:update()` immediately after track switching. Currently, `cmd_cycle_sec_sid` only shows a transient OSD message via `show_osd`, but doesn't force the persistent `drum_osd` overlay to refresh its text.

## Risks / Trade-offs

- **[Risk] Double-setting properties** → [Mitigation] mpv handles redundant property sets efficiently; the visual benefit of zero-flicker outweighs the negligible CPU cost of an extra property set.
- **[Risk] Conflict with user intent** → [Mitigation] We will use the same predicate as `master_tick` to ensure we only suppress if custom OSD rendering is actually active.
