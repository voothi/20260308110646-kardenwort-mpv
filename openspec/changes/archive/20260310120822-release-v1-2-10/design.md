## Context

The previous hardcoded positioning strategy led to a 100% Y-coordinate overlap on some files, causing primary and secondary subtitles to render on top of each other. Furthermore, managing script parameters required editing Lua source code, which was not scalable for non-technical users.

## Goals / Non-Goals

**Goals:**
- Enable external configuration via `mpv.conf`.
- Force a visual separation between top and bottom subtitle tracks.
- Improve the reliability of the "Top/Bottom" state detection.

## Decisions

- **Option Integration**: `lls_core.lua` now initializes `mp.options`, exposing `sec_pos_top` and `sec_pos_bottom` as configurable keys.
- **Explicit Gap**: The default `sec_pos_bottom` is set to 90. This creates a mandatory 5% vertical gap from the default `sub-pos` of 95, preventing collisions.
- **Fuzzy Toggling**: State detection for toggling now checks if a position is above or below 50% of the screen height (`< 50` = Top). This allows the toggle logic to remain functional even if a user provides custom values in `mpv.conf`.
- **Layout Mirroring**: Standard mpv command keys (q, m, [, ], ., ,) are aliased to their Russian counterparts (й, ь, х, ъ, ю, б) in the global configuration.

## Risks / Trade-offs

- **Risk**: Users might still set conflicting values in `mpv.conf`.
- **Mitigation**: Added `[LINKED]` tags in the documentation and `mpv.conf` comments to warn users about the 5% gap dependency.
