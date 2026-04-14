## 1. Core Logic & Configuration

- [x] 1.1 Define `cmd_open_record_file()` in `scripts/lls_core.lua`.
- [x] 1.2 Implement async process launching using `mp.command_native_async` to prevent UI freezing.
- [x] 1.3 Add `record_editor` to the `Options` table and `mpv.conf` for user configurability.
- [x] 1.4 Implement logging via `mp.msg.info` for console-based troubleshooting.

## 2. Keybindings & UI Integration

- [x] 2.1 Map `o` and `щ` in `input.conf` to a script-binding `toggle-record-file` to suppress native mpv behavior.
- [x] 2.2 Implement router logic in `lls_core.lua` to trigger file opening only when Drum Window is active.
- [x] 2.3 Verify that the Drum Window overlay remains stable during and after the file is opened.
