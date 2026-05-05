## 1. Configuration Hardening

- [x] 1.1 Add `seek_time_delta` (default 2) to `Options` in `lls_core.lua`
- [x] 1.2 Add `seek_osd_duration` (default 2.0) to `Options` in `lls_core.lua`
- [x] 1.3 Add corresponding `script-opts-append` entries in `mpv.conf` for both new options

## 2. OSD Refinement

- [x] 2.1 Implement `show_osd_center(msg, dur)` in `lls_core.lua` using `{\an5}` alignment
- [x] 2.2 Increase font size for centered OSD (e.g., `{\fs60}`) for better visibility

## 3. Script-Driven Seeking

- [x] 3.1 Implement `cmd_seek_time(delta)` in `lls_core.lua` that executes seek and shows centered OSD
- [x] 3.2 Add script bindings `lls-seek_time_forward` and `lls-seek_time_backward` to `lls_core.lua`

## 4. Input Configuration

- [x] 4.1 Update `input.conf` to bind `LEFT` and `RIGHT` to the new script commands
- [x] 4.2 Update `input.conf` to bind `A` and `D` (Shift+A/D) to the new script commands
- [x] 4.3 Ensure Russian layout keys (`Ф`, `В`) are correctly mapped via `lls_core` expansion logic
