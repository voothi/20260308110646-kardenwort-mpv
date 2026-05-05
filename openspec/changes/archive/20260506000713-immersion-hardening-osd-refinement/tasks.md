## 1. OSD Descriptive Minimalism

- [x] 1.1 Standardize OSD prefixes for all state toggles (Drum Mode, Window, Book Mode, etc).
- [x] 1.2 Implement context-aware `DW Copied` vs `Copied` feedback logic in `cmd_copy_sub`.
- [x] 1.3 Shorten long OSD prefixes (e.g., `Secondary Sub:`) to maximize screen real estate.
- [x] 1.4 Restore minimalist `ON`/`OFF` confirmation for all system state transitions.

## 2. Interaction Hardening

- [x] 2.1 Refactor `cmd_dw_esc` into a multi-stage reset hierarchy (Pending Set -> Range -> Pointer).
- [x] 2.2 Remove Stage 4 from `cmd_dw_esc` to prevent cyclic mode switching on `Esc`.
- [x] 2.3 Implement forced key bindings using `mp.add_forced_key_binding` for positioning keys.
- [x] 2.4 Silently block `r`, `t`, `R`, `T` keys during active Drum Window or Drum Mode sessions.

## 3. Configuration & State Sync

- [x] 3.1 Update `mpv.conf` with managed subtitle positioning key definitions.
- [x] 3.2 Synchronize the script's `Options` table to support the new `key_sub_pos` configuration parameters.
- [x] 3.3 Ensure the cursor line synchronizes correctly to the active subtitle during `Esc` resets.
