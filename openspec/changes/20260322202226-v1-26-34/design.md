# Design: Universal Navigation Reliability

## System Architecture
The navigation logic is promoted to a global service within `lls_core.lua`, accessible via mpv's script-binding interface.

### Components
1.  **Exported Bindings**:
    - `lls-seek_prev`: Triggers `cmd_dw_seek_delta(-1)`.
    - `lls-seek_next`: Triggers `cmd_dw_seek_delta(1)`.
2.  **Navigation Engine (`cmd_dw_seek_delta`)**:
    - Uses the pre-loaded `Tracks.pri.subs` table for sub-millisecond lookup of target timestamps.
    - Executes `absolute+exact` seeks to bypass the "padding pause" issues of native `sub-seek`.
3.  **Keymap (`input.conf`)**:
    - Centralized mapping of `a`/`d` and `ф`/`в` to the new script-bindings.

## Implementation Strategy
- **Binding Registration**: Use `mp.add_key_binding` with `nil` as the key and a descriptive name (e.g., `lls-seek_next`) to allow `input.conf` to map it to physical keys.
- **Unified Logic Path**: Remove conditional checks for "Drum Mode" inside the core seeking function, making it truly state-agnostic.
- **Verification**: Test navigation immediately following an autopause in both windowed and standard modes to ensure consistent, single-press jumps.
