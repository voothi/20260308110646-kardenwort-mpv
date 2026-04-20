## 1. Options & Defaults

- [x] 1.1 Update `Options.dw_mouse_shield_ms` to `150` in `scripts/lls_core.lua` to establish the new system standard.

## 2. Highlighting Engine Hardening

- [x] 2.1 Refactor the adaptive window calculation in `calculate_highlight_stack` to use `(#term_clean - 10)` to prevent bloat.
- [x] 2.2 Verify window size for a 12-word phrase matches `Base + 1.0s`.

## 3. Interaction Engine Alignment

- [x] 3.1 Replace hardcoded `0.150` literals in `manage_dw_bindings` with `Options.dw_mouse_shield_ms / 1000`.
- [x] 3.2 Implement the modifier-aware check in the `nav` wrapper to exempt Ctrl, Shift, Alt, and Meta from the shield trigger.
- [x] 3.3 Verify that `Shift+UP` and other combos remain responsive after navigation commands.

## 4. Configuration Synchronization

- [x] 4.1 Update `mpv.conf` to set `lls-dw_mouse_shield_ms=150`, ensuring parity between global config and script logic.
- [x] 4.2 Verify through OSD console that the script-opts are correctly injected on player load.
