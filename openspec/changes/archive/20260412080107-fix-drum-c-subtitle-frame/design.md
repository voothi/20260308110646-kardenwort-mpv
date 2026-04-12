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

### 1. Removing Fragile Global State Overrides
The previous implementation used `manage_ui_border_override` to globally mutate the `osd-border-style` property from `background-box` to `outline-and-shadow`. This proved fragile: if the script crashed during search, mpv's global state remained stuck, corrupting the UI indefinitely. 
We will completely disable `manage_ui_border_override` state modification. 

### 2. Native ASS Opacity for UI Isolation
Instead of altering global properties, we will use ASS alpha tags to natively hide the background box on specific elements. By prepending `{\\4a&HFF&}` (Fully Transparent Shadow/Box) directly to the ASS styling payload of Search UI elements, mpv will naturally hide the background box for those UI elements only.
Crucially, this `{\\4a&HFF&}` tag must be injected into *both* text objects **and vector polygons** (`{\p1}m...`) rendered by the Search script, because mpv natively applies `background-box` to all shapes.

### 3. Native Restoration of Drum Mode Subtitles
Because `osd-border-style` will no longer be artificially changed when Search is invoked, Drum Mode C will naturally render its background box natively through mpv, perfectly retaining its premium styling without needing brittle manual box reconstruction logic.

### 4. Safety Net
Provide a `recover_native_osd_style()` routine on script initialization to detect and revert any previous state corruption left over from old script crashes, ensuring users don't encounter mysteriously missing backgrounds.

## Risks / Trade-offs
- **Risk**: Finding every ASS block to inject the opacity tag can easily miss an element if new UI panels are added.
- **Trade-off**: This approach strictly abides by mpv's intended rendering design, fundamentally resolving the visual bugs without mutating global states that break the rest of the application ecosystem.
