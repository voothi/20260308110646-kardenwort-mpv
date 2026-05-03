## 1. Core Logic Refactoring

- [x] 1.1 Implement `gd_` prefix naming convention in `Options` and `mpv.conf`
- [x] 1.2 Implement dual-mode lookup support (`side` vs `main`) in all copy commands
- [x] 1.3 Implement Win32 `keybd_event` VK-based injection engine
- [x] 1.4 Refactor `set_clipboard` to be layout-independent and non-blocking (async)
- [x] 1.5 Register global `Ctrl+Alt+C` binding for main dictionary window

## 2. Verification

- [x] 2.1 Verify reliable triggering in EN layout (Ctrl+Alt+Shift+Q)
- [x] 2.2 Verify reliable triggering in RU layout (Ctrl+Alt+Shift+й)
- [x] 2.3 Verify zero "garbage" character injection in search fields
- [x] 2.4 Verify non-blocking operation (no MPV stutter during trigger)
