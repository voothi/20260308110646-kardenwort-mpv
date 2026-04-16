## 1. Input Bindings & Configuration

- [x] 1.1 Add new parameters to the "Translation Tooltip Settings" section of `mpv.conf` (e.g., `lls-dw_tooltip_toggle_key=e` and `lls-dw_tooltip_toggle_key_ru=у`).
- [x] 1.2 Bind these configured keys to trigger the new tooltip toggle action within the script's initialization layout.

## 2. Core Implementation

- [x] 2.1 Implement a `toggle_tooltip()` or similar function in `lls_core.lua` (or the relevant Tooltip module) that manages a boolean state for keyboard-driven tooltip visibility.
- [x] 2.2 Restrict the `toggle_tooltip()` function execution to only occur when the Drum Window ('w') is currently open/active.
- [x] 2.3 Connect the toggle function to the existing tooltip rendering routine, ensuring it fetches the subtitle text based on the current playback time rather than relying on a mouse position intersection.
- [x] 2.3 Modify the tooltip dismiss logic to ensure it can be closed by the subsequent key press while not breaking hover-off behavior.

## 3. Verification

- [x] 3.1 Test that pressing `e` or `у` when a subtitle is present displays its tooltip correctly.
- [x] 3.2 Test that pressing the key again successfully hides the tooltip.
- [x] 3.3 Regress mouse hover behavior to ensure mouse-driven tooltips still work as expected.
