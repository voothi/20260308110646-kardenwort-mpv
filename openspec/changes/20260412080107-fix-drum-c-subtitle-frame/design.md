# Design: Drum Mode C Subtitle Frame Persistence

## Context
The project uses `osd-border-style=background-box` for a premium look. To prevent this style from cluttering custom UIs (Search, Drum Window), a global override mechanism exists. However, this mechanism doesn't account for the fact that Drum Mode C *is* an OSD-based UI that expects the background box to be preserved.

## Goals / Non-Goals

**Goals:**
- Ensure Drum Mode C subtitles retain their background box when Search is active.
- Minimize changes to existing UI logic.
- Maintain the "Black Frame" aesthetic for subtitles at all times.

**Non-Goals:**
- Perfectly styling the Search UI when Drum Mode is active (minor visual artifacts are acceptable).
- Refactoring the entire OSD rendering system.

## Decisions

### 1. Granular Background Box Control via ASS
Instead of a global toggle, we will use the `\4a` (shadow alpha) ASS tag to control the visibility of the background box on a per-element basis.

**Rationale:**
Since `osd-border-style=background-box` uses the shadow alpha for box opacity, we can hide the box by setting `{\\4a&HFF&}` (fully transparent) and show it by setting `{\\4a&H00&}` (opaque) or using the global default. This allows the Search UI to stay "light" (no extra boxes) while the Drum Subtitles stay "dark" (with their frame).

### 2. Update OSD Renderers
- **`draw_search_ui`**: Add `{\\4a&HFF&}` to all text lines.
- **`draw_dw`**: Ensure `{\\4a&HFF&}` is used for main text blocks.
- **`draw_drum`**: Explicitly set `{\\4a&H00&}` or similar to preserve the subtitle frame.

### 3. Simplify Global Style Logic
The `manage_ui_border_override` function will be modified to NOT change the `osd-border-style`. This prevents flickering and global property drift.


## Risks / Trade-offs

- **Risk**: The Search UI will look slightly different (extra frames around text) if opened while Drum Mode C is active.
- **Trade-off**: This is acceptable as a "minimally invasive" fix that solves the primary bug reported by the user without introducing complex manual rendering logic.
