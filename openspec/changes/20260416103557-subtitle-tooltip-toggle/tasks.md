## 1. Input Bindings & Configuration

- [x] 1.1 Add new parameters to the "Translation Tooltip Settings" section of `mpv.conf` (e.g., `lls-dw_tooltip_toggle_key=e` and `lls-dw_tooltip_toggle_key_ru=у`).
- [x] 1.2 Bind these configured keys to trigger the new tooltip toggle action within the script's initialization layout.

## 2. Core Implementation

- [x] 2.1 Implement a `toggle_tooltip()` or similar function in `lls_core.lua` (or the relevant Tooltip module) that manages a boolean state for keyboard-driven tooltip visibility.
- [x] 2.2 Restrict the `toggle_tooltip()` function execution to only occur when the Drum Window ('w') is currently open/active.
- [x] 2.3 Connect the toggle function to the existing tooltip rendering routine, ensuring it fetches the subtitle text based on the current playback time rather than relying on a mouse position intersection.
- [x] 2.4 Modify the tooltip dismiss logic to ensure it can be closed by the subsequent key press while not breaking hover-off behavior.

## 3. Dynamic Positioning (Scrolling)

- [x] 3.1 Modify the Drum Window rendering logic (`draw_dw`) to calculate and store the OSD Y-coordinates for every visible subtitle line.
- [x] 3.2 Implement a mechanism to retrieve a line's current on-screen Y-position by its subtitle index.
- [x] 3.3 Update the tooltip refresh logic (in `tick_dw` or similar) to reposition the active tooltip based on its line's current Y-position on every tick.
- [x] 3.4 Ensure the dynamic positioning applies to both keyboard-toggled (`FORCE`) and mouse-pinned (`HOLDING`) tooltips.

## 4. Navigation & Focus Tracking

- [x] 4.1 Update `dw_tooltip_mouse_update` (or the refresh routine) to detect if the target line for a keyboard-forced tooltip (`FORCE`) has changed (e.g., via `DW_CURSOR_LINE` or active playback).
- [x] 4.2 In Book Mode, ensure the keyboard tooltip ('e') automatically updates its `sub_idx` to follow the current playback position as the user seeks with `a`/`d`.
- [x] 4.3 Ensure manual mouse selection still correctly updates the tooltip when forced.

## 5. Verification

- [x] 5.1 Test that the tooltip follows its associated line when scrolling.
- [x] 5.2 **Book Mode Verification**: Toggle 'e', then use 'a' and 'd' keys to navigate. Verify the tooltip content and position update automatically to match the new white/highlighed line.
- [x] 5.3 Verify that manual LMB selection still works as expected with a forced tooltip.
- [x] 5.4 Regress mouse hover behavior.
