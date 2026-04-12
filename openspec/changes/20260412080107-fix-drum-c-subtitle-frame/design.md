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

### 1. Conditional Override in `manage_ui_border_override`
We will modify the `manage_ui_border_override` function to check the `FSM.DRUM` state. 

**Rationale:**
The override to `outline-and-shadow` is primarily to benefit the Search UI and Drum Window (W). However, if Drum Mode C is active, it relies on the OSD background box for subtitle readability. By skipping the override when `FSM.DRUM == "ON"`, we ensure the subtitles remain legible.

### 2. Priority Logic
In the event of a conflict (e.g., both Search and Drum Mode are active), we prioritize the visibility and styling of the primary content (subtitles) over the perfection of the search interface.

### 3. State Sequence Safety
Since `manage_ui_border_override` handles its own idempotent state (`saved_osd_border_style`), skipping the override simply means the property isn't changed and the restoration logic is similarly skipped (as `saved_osd_border_style` remains `nil`).

## Risks / Trade-offs

- **Risk**: The Search UI will look slightly different (extra frames around text) if opened while Drum Mode C is active.
- **Trade-off**: This is acceptable as a "minimally invasive" fix that solves the primary bug reported by the user without introducing complex manual rendering logic.
