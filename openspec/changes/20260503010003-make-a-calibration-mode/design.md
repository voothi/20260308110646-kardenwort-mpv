# Design: Calibration Mode (Visual Debug & Self-Adjusting)

## Context

The Kardenwort-mpv interaction engine uses heuristic-based word boundary detection. Currently, the multipliers for these heuristics are hardcoded in `Options` and can be overridden in `mpv.conf`. However, there is no way to see if the hit-zones actually match the text without tedious manual testing.

## Goals / Non-Goals

**Goals:**
- Provide a high-contrast visual overlay of all active hit-zones.
- Allow real-time tuning of multipliers via keyboard.
- Persist calibrated values to the filesystem.
- Maintain O(1) rendering performance during calibration.

**Non-Goals:**
- Automatic OCR-based calibration.
- Persistent UI menus (will use OSD notifications).
- Support for complex non-monospace font calibration in the first iteration.

## Decisions

1.  **Overlay Implementation**: Use a dedicated `mp.create_osd_overlay("ass-events")` with a high Z-index (e.g., 35) to render magenta boxes (`{\1c&HFF00FF&\1a&H80&}`) over the text. This avoids modifying the existing `drum_osd` or `dw_osd` logic.
2.  **Transient Keybindings**: Implement a state-based keybinding group using `mp.add_forced_key_binding`. When `FSM.CALIBRATION_MODE` is enabled, standard navigation keys will be remapped to multiplier adjustments.
3.  **Real-Time Cache Flushing**: Every adjustment will trigger `flush_rendering_caches()` and `FSM.LAYOUT_VERSION = FSM.LAYOUT_VERSION + 1`. This forces the OSD to recalculate all hit-zones and re-render the overlay at 60fps.
4.  **Persistence Mechanism**: Calibrated values will be appended to the user's `mpv.conf` (or a `calibration.conf` if detected) using a standard Lua I/O append operation. The entries will be commented with the current ZID and a "DO NOT EDIT" warning.
5.  **Multipliers to Expose**:
    - `dw_char_width`: Steps of 0.001.
    - `dw_line_height_mul`: Steps of 0.01.
    - `dw_vsp`: Steps of 1 pixel.
    - `dw_block_gap_mul`: Steps of 0.01.

## Risks / Trade-offs

- **Risk**: Appending to `mpv.conf` could lead to multiple conflicting definitions of the same property.
    - **Mitigation**: Standard `mpv` behavior is that the *last* definition wins. We will use this to our advantage.
- **Trade-off**: Monospace-only focus. Proportional fonts require a much more complex per-character width map which is out of scope for the initial "Visual Debug" implementation.
