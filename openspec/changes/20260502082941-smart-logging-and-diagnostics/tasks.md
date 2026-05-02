## 1. Diagnostic Module Implementation

- [ ] 1.1 Define the `Diagnostic` table with level constants and `mp.msg` mapping.
- [ ] 1.2 Implement the `Diagnostic.log(level, msg)` function with deduplication logic.
- [ ] 1.3 Add level-specific helpers (`Diagnostic.info`, `Diagnostic.warn`, etc.).

## 2. Global Refactoring

- [ ] 2.1 Replace all `print("[LLS] ...")` and `print("[LLS ERROR] ...")` calls with `Diagnostic` calls.
- [ ] 2.2 Map periodic success messages (like TSV Load) to `Diagnostic.trace` or `Diagnostic.debug`.
- [ ] 2.3 Ensure error paths remain at `Diagnostic.error` or `Diagnostic.warn`.

## 3. Configuration & Startup

- [ ] 3.1 Add `log_level` to `Options` and register it in `on_options_change`.
- [ ] 3.2 Implement `validate_config()` to check for invalid keybindings (Cyrillic names, etc.) and missing files.
- [ ] 3.3 Call `validate_config()` during initialization and output a single summary warning if issues are found.
- [ ] 3.4 Clean up the one-time warning logic from `manage_dw_bindings` in favor of the new centralized validation.
