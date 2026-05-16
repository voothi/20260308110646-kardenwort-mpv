## 1. Verification Framework

- [ ] 1.1 Create `tests/acceptance/test_20260516204609_dw_esc_mode_cycling.py` following the established Python/pytest pattern.
- [ ] 1.2 Ensure the test fixture correctly loads the `mpv` instance with the `kardenwort` script and custom `mpv.conf`.

## 2. Omnidirectional Testing

- [ ] 2.1 **Cycling Loop Test**: Implement a test that sends multiple `n` keypresses and verifies the internal `Options.dw_esc_mode` state transitions correctly through `auto_follow_current`, `neutral_last_selection`, and `neutral_current_subtitle`.
- [ ] 2.2 **OSD Parity Test**: Implement verification for OSD messages to ensure they match the required "professional labels" (e.g., `DW Esc Mode: AUTO FOLLOW CURRENT`).
- [ ] 2.3 **Cyrillic Parity Test**: Implement a test that sends the `т` key and verifies it triggers the same cycling logic as `n`.
- [ ] 2.4 **State Persistence Test**: Verify that the selected `DW Esc Mode` remains active after closing and reopening the Drum Window.

## 3. Documentation & Finalization

- [ ] 3.1 Update the project's internal feature list or help documentation to include `DW Esc Mode`.
- [ ] 3.2 Run the full acceptance suite and attach the results to the change log.
