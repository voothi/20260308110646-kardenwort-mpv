## 1. Core Logic Refactoring

- [x] **Phase 1: Unified Clipboard Abstraction**
  - [x] Refactor `set_clipboard` to handle mode-based triggering.
  - [x] Implement unified OSD with cooldown suppression.
- [x] **Phase 2: High-Performance Trigger Bridge**
  - [x] Implement PowerShell Win32 `keybd_event` injector.
  - [x] Implement Python `ctypes` injector with configurable delays.
- [x] **Phase 3: Triple-Tier Decoupling**
  - [x] Decouple Standard Copy (`Ctrl+C`) from dictionary lookups.
  - [x] Implement separate `key_copy_popup` and `key_copy_main` configurability.
- [x] **Phase 4: Recursion Hardening**
  - [x] Implement `gd_trigger_lock_duration` to prevent AHK loop feedback.
  - [x] Synchronize documentation and `mpv.conf` schema.

## 2. Verification

- [x] 2.1 Verify reliable triggering in EN layout (Ctrl+Alt+Shift+Q)
- [x] 2.2 Verify reliable triggering in RU layout (Ctrl+Alt+Shift+й)
- [x] 2.3 Verify zero "garbage" character injection in search fields
- [x] 2.4 Verify non-blocking operation (no MPV stutter during trigger)
