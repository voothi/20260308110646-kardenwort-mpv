## 1. Input Bindings

- [ ] 1.1 Add keybindings for `e` and cyrillic `у` in mpv configuration or directly into the script initialization to trigger the new tooltip toggle action.

## 2. Core Implementation

- [ ] 2.1 Implement a `toggle_tooltip()` or similar function in `lls_core.lua` (or the relevant Tooltip module) that manages a boolean state for keyboard-driven tooltip visibility.
- [ ] 2.2 Connect the toggle function to the existing tooltip rendering routine, ensuring it fetches the subtitle text based on the current playback time rather than relying on a mouse position intersection.
- [ ] 2.3 Modify the tooltip dismiss logic to ensure it can be closed by the subsequent key press while not breaking hover-off behavior.

## 3. Verification

- [ ] 3.1 Test that pressing `e` or `у` when a subtitle is present displays its tooltip correctly.
- [ ] 3.2 Test that pressing the key again successfully hides the tooltip.
- [ ] 3.3 Regress mouse hover behavior to ensure mouse-driven tooltips still work as expected.
