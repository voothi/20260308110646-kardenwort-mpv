## 1. Diagnostic Module Implementation

- [x] 1.1 Define the `Diagnostic` table with level constants and `mp.msg` mapping.
- [x] 1.2 Implement the `Diagnostic.log(level, msg)` function with deduplication logic.
- [x] 1.3 Add level-specific helpers (`Diagnostic.info`, `Diagnostic.warn`, etc.).

## 2. Global Refactoring

- [x] 2.1 Replace all `print("[LLS] ...")` and `print("[LLS ERROR] ...")` calls with `Diagnostic` calls.
- [x] 2.2 Map periodic success messages (like TSV Load) to `Diagnostic.trace` or `Diagnostic.debug`.
- [x] 2.3 Ensure error paths remain at `Diagnostic.error` or `Diagnostic.warn`.

## 3. Configuration & Startup

- [x] 3.1 Add `log_level` to `Options` and register it in `on_options_change`.
- [x] 3.2 Implement `validate_config()` to check for invalid keybindings (Cyrillic names, etc.) and missing files.
- [x] 3.3 Call `validate_config()` during initialization and output a single summary warning if issues are found.
- [x] 3.4 Clean up the one-time warning logic from `manage_dw_bindings` in favor of the new centralized validation.
- [x] 3.5 Purge invalid multicharacter Cyrillic aliases from `lls_core.lua` and `mpv.conf`.
- [x] 3.6 Demote `OPENING/CLOSING DRUM WINDOW` logs to `Diagnostic.debug`.
- [x] 3.7 Bind `ё` to `console/enable` in `input.conf` for layout-agnostic debugging.
