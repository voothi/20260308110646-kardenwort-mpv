## Context

The current `lls_core.lua` script provides a "Drum Window" (Mode W) with full interactivity, but Drum Mode (Mode C) and Normal Mode (standard subtitles) are mostly non-interactive views. Highlighting in these modes is limited to Anki hits. The existing mouse selection engine is tightly coupled to the `draw_dw` layout, making it difficult to use for the dynamic, centered overlays used in other modes.

## Goals / Non-Goals

**Goals:**
- Generalize hit-testing logic to support dynamic, centered OSD layouts.
- Enable full word-level interactivity (selection, tooltips, Anki additions) for the `drum_osd` overlay.
- Maintain high performance by caching hit-zone metadata and only recalculating when the subtitle segment or positioning changes.
- Ensure full compatibility with `sub-pos` and `secondary-sub-pos` configuration hotkeys.

**Non-Goals:**
- Adding interactivity to native ASS/SSA styled subtitles (interactivity is only supported when LLS OSD rendering is active).
- Implementing complex multi-line drag selection for the small OSD strips (focus on word-level and single-line selection).

## Decisions

### 1. Unified Hit-Testing Engine
**Decision**: Refactor the hit-testing logic to use a metadata-driven approach. A new utility function will calculate bounding boxes for words based on the current rendering parameters (text, font size, position).
- **Rationale**: Decouples rendering from interaction, allowing the same logic to be used for the Drum Window, Drum Mode, and standard OSD subtitles.
- **Alternatives**: Using native mpv `sub-text` coordinates? Not possible for OSD overlays.

### 2. Hit-Zone Metadata Caching
**Decision**: Store the calculated hit-zones for the currently visible `drum_osd` lines in a transient state variable (`FSM.DRUM_HIT_ZONES`).
- **Rationale**: Avoids expensive string width calculations on every mouse movement, ensuring smooth performance.
- **Update Trigger**: Hit-zones are recalculated only when a new subtitle segment is entered or when a position-altering hotkey (e.g., `r`, `t`) is pressed.

### 3. Coordinate Normalization
**Decision**: Use isotropic coordinate mapping (porting from `dw_get_mouse_osd`) to ensure mouse clicks land correctly regardless of the player's window aspect ratio or scaling.
- **Rationale**: Prevents "drift" where click targets become misaligned when the window is resized to non-16:9 ratios.

## Risks / Trade-offs

- **Moving Targets** → Clicking on subtitles during high-speed playback can be frustrating. 
  - *Mitigation*: The system will leverage existing AutoPause logic or a "Click-to-Pause" behavior to stabilize the UI during interaction.
- **Performance Overhead** → Continuous hit-testing on every `tick_rate`.
  - *Mitigation*: Use a bounding box pre-filter to ignore mouse events outside the active subtitle area.
