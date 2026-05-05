## 1. Configuration Expansion

- [x] 1.1 `seek_font_*` and `seek_color` options are already present
- [x] 1.2 Add `seek_show_accumulator` (default `yes`) to `Options` in `lls_core.lua`
- [x] 1.3 Add `seek_show_accumulator` to `mpv.conf`

## 2. State Tracking Implementation

- [x] 2.1 Initialize `FSM.SEEK_ACCUMULATOR = 0` and `FSM.SEEK_LAST_TIME = 0` in `lls_core.lua`
- [x] 2.2 Implement accumulator logic in `cmd_seek_time`:
    - Check if current seek is within `seek_osd_duration` of `SEEK_LAST_TIME`.
    - Update `SEEK_ACCUMULATOR` accordingly.
    - Reset `SEEK_ACCUMULATOR` if window expired.

## 3. OSD Refinement (Accumulator)

- [x] 3.1 Update `show_seek_osd` or its caller to format the cumulative string: `+2 (+4)`
- [x] 3.2 Ensure the OSD message duration is correctly handled to act as a "rewind ongoing" indicator.

## 4. Verification

- [x] 4.1 Test consecutive seeks within the duration and verify the accumulator increments.
- [x] 4.2 Verify that the accumulator resets after the OSD disappears.
