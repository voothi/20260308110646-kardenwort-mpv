## Context

The current subtitle layout engine for Drum Window (Mode W) and Drum Mode (Mode C) calculates the visible range as a fixed radius around a logical center index. For example, if 15 lines are visible, it attempts to show 7 lines above and 7 lines below the center. When navigation reaches the end of the subtitle track, this logic simply truncates the range at the boundary, resulting in only 8 lines being displayed. Since the OSD block is centered on the screen, this "shrunken" block causes the text to shift vertically and creates unnecessary empty space.

## Goals / Non-Goals

**Goals:**
- Maintain high information density by always showing the maximum possible number of context lines at the beginning and end of a track.
- Standardize the visual behavior between arrow key navigation (which already clamps indices correctly) and mouse wheel/seeking.
- Ensure the OSD block height remains stable near boundaries.

**Non-Goals:**
- Changing the underlying index-based layout engine to a pixel-based smooth scroll engine.
- Modifying the user configuration for visible line counts.

## Decisions

### 1. Unified Sliding Window Logic
Instead of simple radius-based indexing, we will implement a boundary-aware sliding window calculation in the core drawing functions.

**Logical implementation:**
```lua
radius = floor(desired_count / 2)
start = center - radius
finish = center + radius (adjusted for parity)

if start < 1:
   offset = 1 - start
   start = 1
   finish = finish + offset
end

if finish > total:
   offset = finish - total
   finish = total
   start = start - offset
end

start = max(1, start)
finish = min(total, finish)
```

### 2. Implementation in `dw_build_layout`
This function is responsible for the Drum Window (Mode W). It will be updated to use this sliding logic to ensure exactly `Options.dw_lines_visible` lines are included in the layout entry list whenever `#subs` allows.

### 3. Implementation in `draw_drum`
This function handles Drum Mode (Mode C) and standard SRT/ASS rendering. It will be updated using the same principle for `Options.drum_context_lines`, ensuring that the preceding and succeeding context fills the available "vertical slots" even when the active line is at the track boundary.

## Risks / Trade-offs

**Active Line Vertical Shifting:**
With this change, when the user scrolls to the very last line, the "active" or "centered" subtitle will move from the middle of the screen towards the bottom (as it is now at the end of a full 15-line block). However, this is consistent with standard list-view scrolling behavior found in most document and text editors, and it is preferred over the current "shrinking block" behavior.
