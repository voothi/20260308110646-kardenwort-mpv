## 1. Hotkey Expansion Hardening

- [x] 1.1 Update `expand_ru_keys` to strictly map Shift-modified English keys to uppercase Cyrillic characters only, omitting `Shift+lowercase` variants.
- [x] 1.2 Implement a `seen` tracking table in `expand_ru_keys` to prevent redundant or duplicate binding registrations across multi-part option strings.
- [x] 1.3 Enhance expansion logging to include the option name (`opt_name`) for better diagnostic context during initialization.

## 2. Diagnostic Tracing Implementation

- [x] 2.1 Wrap Drum Window `add_forced_key_binding` calls in a diagnostic wrapper that logs the raw triggering key and logical binding name when `log_level=debug`.
- [x] 2.2 Wrap global `add_key_binding` calls (copy and position groups) in a diagnostic wrapper to trace "ghost" triggers to their source options.
- [x] 2.3 Implement startup expansion auditing that logs the final resolved binding list for every layout-agnostic option.

## 3. Option Sanitization and Initialization

- [x] 3.1 Sanitize `Options` table defaults by removing hardcoded Russian duplicates, ensuring the expansion engine is the sole source of truth.
- [x] 3.2 Consolidate and move configuration reading (`read_options`) and validation to the start of the script's initialization phase.
