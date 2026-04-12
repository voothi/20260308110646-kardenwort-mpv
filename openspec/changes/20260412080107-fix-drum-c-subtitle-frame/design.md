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

### 1. Robust Manual Frame for Drum Subtitles
To handle the global style override during search, the Drum Mode renderer will implement a manual background box drawing when `FSM.saved_osd_border_style` is detected.

**Rationale:**
Since global OSD properties cannot be set per-overlay, drawing a standard ASS rectangle (`{\\p1}`) behind the subtitles is the only way to maintain the "Black Frame" aesthetic while the search UI is active.

### 2. Refined Parameters
- **Check**: We will check `if FSM.saved_osd_border_style then` to ensure the box activates on any override.
- **Alpha**: We will use `{\\1a&H3F&}` (which corresponds to ~75% opacity) to match the project's `#C0000000` styling.
- **Width Heuristic**: Use `dw_get_str_width` to dynamically scale the box width to the subtitle content, with a generous safety margin (+80px).

### 3. Maintain Global Logic
We will keep the original `manage_ui_border_override` property toggling. This ensures that non-drum elements (Search, DW) remain clean and box-free without requiring per-tag alpha injection on every OSD event.



## Risks / Trade-offs

- **Risk**: The Search UI will look slightly different (extra frames around text) if opened while Drum Mode C is active.
- **Trade-off**: This is acceptable as a "minimally invasive" fix that solves the primary bug reported by the user without introducing complex manual rendering logic.
