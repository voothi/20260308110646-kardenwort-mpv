## 1. Preparation

- [x] 1.1 Add `FSM.HELP_MODE` to the State Machine in `main.lua`.
- [x] 1.2 Initialize `help_osd` overlay using `mp.create_osd_overlay`.

## 2. Dynamic Key Discovery Engine

- [x] 2.1 Implement `get_active_binding(cmd_name)` helper to scan `input-bindings` and `Options`.
- [x] 2.2 Define the help schema (Mapping actions to friendly descriptions).

## 3. Rendering Logic

- [x] 3.1 Implement `render_help()` function using ASS tags for styling.
- [x] 3.2 Add multi-column support for the help text to ensure it fits on screen.
- [x] 3.3 Implement `cmd_toggle_help()` to switch `FSM.HELP_MODE` and trigger rendering.

## 4. Integration

- [x] 4.1 Bind `F1` to `cmd_toggle_help` in the global keybinding section.
- [x] 4.2 Ensure `ESC` closes the Help HUD if it's open.
- [x] 4.3 Add Russian layout counterpart for `F1`.

## 5. Verification

- [x] 5.1 Verify that Help HUD displays correct keys after remapping in `mpv.conf`.
- [x] 5.2 Verify visual alignment and premium aesthetics.
