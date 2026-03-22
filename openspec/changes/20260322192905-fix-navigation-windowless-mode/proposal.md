# Proposal: Fix Navigation in Windowless Mode

## Summary
Extend the reliable subtitle navigation fix (from the Drum Window) to work globally in "windowless mode" by exporting the seeking logic as script-bindings and updating `input.conf`.

## Problem
The recent fix for the "double-tap" navigation issue (where the `d` key required two presses after an autopause) was only implemented for the Drum Window's forced key bindings.

When the Drum Window is closed (windowless mode), the `a` and `d` keys revert to the standard `sub-seek` command defined in `input.conf`. This native command remains unreliable in the "pause-at-padding" state, forcing the user to press the key twice to jump to the actual next subtitle.

## Proposed Solution
1.  **Export Script Bindings**: Modify `lls_core.lua` to register `cmd_dw_seek_delta(-1)` and `cmd_dw_seek_delta(1)` as formal script-bindings (e.g., `lls-seek_prev` and `lls-seek_next`).
2.  **Update Global Bindings**: Update `input.conf` to use these script-bindings for the `a`, `d`, `ф`, and `в` keys instead of the native `sub-seek` command.
3.  **Refactor DRUM Mode Bindings**: (Optional) Simplify `manage_dw_bindings` to use these same script-bindings or continue using the functions directly for consistency.

## Benefits
-   **Universal Reliability**: Subtitle navigation will respond on the first press regardless of whether the Drum Window is open or closed.
-   **Agnostic Logic**: The `cmd_dw_seek_delta` logic is already robust and uses the internal subtitle table, which is more precise than `sub-seek`.
-   **Consistency**: `a` and `d` behave identically in all player states.

## Verification Plan
1.  Close the Drum Window.
2.  Allow the video to autopause (or pause manually near the end of a subtitle).
3.  Press `d`: Verify it jumps to the next subtitle on the first press.
4.  Press `a`: Verify it jumps to the previous subtitle on the first press.
5.  Open the Drum Window and repeat the tests.
