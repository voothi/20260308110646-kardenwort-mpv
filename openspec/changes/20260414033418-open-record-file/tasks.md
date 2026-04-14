## 1. Core Logic Implementation

- [x] 1.1 Define `cmd_open_record_file()` in `scripts/lls_core.lua`.
- [x] 1.2 Implement logic in `cmd_open_record_file` to get TSV path, verify existence, and launch OS default editor via PowerShell.
- [x] 1.3 Add user feedback using `show_osd` for both success and error states (e.g., file not found).

## 2. UI Hooking

- [x] 2.1 Modify `manage_dw_bindings` in `scripts/lls_core.lua` to include 'o' and 'щ' (RU layout) in the `keys` table.
- [x] 2.2 Ensure the new bindings correctly trigger `cmd_open_record_file()` when the Drum Window is active.
