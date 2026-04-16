## Context

Currently, the tooltip system for displaying subtitle translation/context information is entirely mouse-driven (appearing on hover). Keyboard-only users need a way to display this tooltip without reaching for the mouse. The requested keys are 'e' and the cyrillic 'у' (which occupy the same physical key on standard EN/RU layouts).

## Goals / Non-Goals

**Goals:**
- Bind the 'e' and 'у' keys to toggle the visibility of the tooltip for the currently displayed subtitle.

**Non-Goals:**
- Altering existing tooltip styles, layout, or content.
- Changing the existing hover-based mouse behavior.

## Decisions

- **Keybindings (`input.conf` or script bindings):** We will map the "e" and "у" keys to a script function that explicitly toggles the tooltip state. 
- **State tracking:** The Tooltip system (likely `lls_core.lua` or similar module) will need a new state flag (e.g., `tooltip_keyboard_toggled`) to track whether the tooltip was invoked via keyboard vs. mouse, or simply re-use the existing display logic forced on the current active subtitle string.
- **Hide mechanism:** Pressing the key again while the tooltip is shown will explicitly hide it.

## Risks / Trade-offs

- **Risk:** Keybinding conflicts. 'e' may be used by default mpv for adjusting video parameters, though it is usually unbound or less critical.
  - **Mitigation:** We will override the binding within the script's context to ensure it works properly inside our application environment without unintentional side-effects.
