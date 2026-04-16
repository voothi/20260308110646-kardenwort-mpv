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
- **Hide mechanism:** Pressing the key again while the tooltip is shown will explicitly hide it.
- **Dynamic Y-Positioning:** To ensure the tooltip follows its subtitle during scrolling, the Drum Window's rendering engine will calculate and track the absolute Y-position of each line. When a tooltip is active (pinned or forced), its `osd_y` coordinate will be updated every tick to match the vertical center of the corresponding subtitle line on screen.
- **Navigation Tracking (Book Mode Focus):** When the keyboard tooltip ('e') is active, it will dynamically update the target `sub_idx` to match the current focus line (keyboard cursor or playback active line). This ensures that navigating with `a`/`d` keys or advancing via playback automatically shifts the tooltip to the new active subtitle.

## Risks / Trade-offs

- **Risk:** Keybinding conflicts. 'e' may be used by default mpv for adjusting video parameters, though it is usually unbound or less critical.
  - **Mitigation:** We will override the binding within the script's context to ensure it works properly inside our application environment without unintentional side-effects.
