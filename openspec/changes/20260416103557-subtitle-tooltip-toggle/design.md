## Context

Currently, the tooltip system for displaying subtitle translation/context information is entirely mouse-driven (appearing on hover). Keyboard-only users need a way to display this tooltip without reaching for the mouse, specifically when interacting with the Drum Window ('w'). The requested keys are 'e' and the cyrillic 'у' (which occupy the same physical key on standard EN/RU layouts).

## Goals / Non-Goals

**Goals:**
- Bind the 'e' and 'у' keys to toggle the visibility of the tooltip for the active subtitle inside the Drum Window ('w').
- Expose these keys as configurable parameters in `mpv.conf` to remain flexible and easily discoverable.

**Non-Goals:**
- Altering existing tooltip styles, layout, or content.
- Changing the existing hover-based mouse behavior.

## Decisions

- **Keybindings via `mpv.conf` parameters:** We will expose new parameters (e.g., `lls-dw_tooltip_toggle_key=e` and `lls-dw_tooltip_toggle_key_ru=у`) under the Translation Tooltip Settings or Drum Window Settings in `mpv.conf` to define the keys used for toggling.
- **Scope limitation:** The keyboard toggle functionality will strictly check if the Drum Window ('w') is currently active or focused. This ensures the tooltip only appears in the expected context.
- **State tracking:** The Tooltip system (`lls_core.lua`) will use these parameter values to bind an explicit `toggle_tooltip()` function.
- **Robust Toggle Logic:** To prevent scenarios where the tooltip cannot be dismissed (e.g., when the target subtitle has changed due to seeking in Book Mode), the 'OFF' transition of the toggle key ('e') SHALL rely strictly on the `FSM.DW_TOOLTIP_FORCE` state rather than matching a specific line index. If the forced state is active, the next press always dismisses it.
- **Hide mechanism:** Pressing the key again while the tooltip is shown via keyboard-force will explicitly hide it.
- **Dynamic Y-Positioning:** To ensure the tooltip follows its subtitle during scrolling, the Drum Window's rendering engine will calculate and track the absolute Y-position of each line. When a tooltip is active (pinned or forced), its `osd_y` coordinate will be updated every tick to match the vertical center of the corresponding subtitle line on screen.
- **Context-Sensitive Targeting (Book Mode Support):** During playback (video not paused), the toggled keyboard tooltip ('e') will dynamically follow the **active playback subtitle** (white highlight).
- **Sub-Priority Tracking (Paused State):** When playback is paused, the toggled tooltip ('e') uses an interaction-based priority:
  - If the user **seeks or scrolls** (e.g., via `a`/`d` or playback jump), the tooltip follows the **active subtitle** (white).
  - If the user **moves the cursor** (e.g., via arrows), the tooltip follows the **yellow cursor**.
  - This allows users to review the text independently of the playback position while still having the tooltip jump to the active line when seeking.
- **Book Mode Cursor Decoupling:** In Book Mode ON, the manual selection cursor (yellow) is explicitly decoupled from the active playback subtitle (white). This allows users to study sections of text while hearing audio from a different section, a critical use case for language learning.
- **RMB Logic Preservation (Regression Fix):** The Right Mouse Button (RMB) behavior SHALL be restored to its original functionality. This includes:
  - **Dynamic Dragging (Force-Hover):** While RMB is held down (`DW_TOOLTIP_HOLDING`), the tooltip SHALL dynamically follow the currently hovered subtitle line (`line_idx`). This allows users in `CLICK` mode to "swipe" across text to quickly see translations without multiple clicks.
  - **CLICK Mode Dismissal:** In standard `CLICK` mode (or while over a selection range in `HOVER` mode), moving the mouse focus away from the pinned/held line SHALL immediately dismiss the tooltip. This ensures that tooltips do not "stick" unintentionally after a click-and-drag or a simple coordinate-pinned view.

## Risks / Trade-offs

- **Risk:** Keybinding conflicts. 'e' may be used by default mpv for adjusting video parameters, though it is usually unbound or less critical.
  - **Mitigation:** We will override the binding within the script's context to ensure it works properly inside our application environment without unintentional side-effects.
