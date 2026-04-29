## Why

The wrapping refactor introduced in `67ee625` (`draw_drum` / `calculate_osd_line_meta`) introduced four regressions: an inter-subtitle gap is measured using the **current** subtitle's font size rather than the **previous** one's, empty subtitle entries no longer reserve their slot height, the `cur_y` variable was accidentally de-initialized causing a nil-arithmetic crash in `draw_drum`, and `calculate_osd_line_meta` is now called unconditionally every frame even when OSD interactivity is disabled. These cause visible vertical misalignment, full rendering crashes in Drum mode, and unnecessary CPU overhead.

## What Changes

- **Fix gap-size source in `draw_drum`**: The `calculate_sub_gap` call inside the `cur_y` advance loop and the `total_h` accumulation loop SHALL use the **previous** (just-finished) subtitle's `size`, not the upcoming one's.
- **Restore `cur_y` initialization**: The `local cur_y = y_start` declaration MUST be restored before the rendering loop in `draw_drum` to prevent nil-arithmetic crashes.
- **Fix empty-subtitle height**: `calculate_osd_line_meta` SHALL return a `total_height` equal to `(font_size * line_height_mul) + vsp` even when the subtitle text is empty.
- **Guard `calculate_osd_line_meta` behind interactivity flag**: The meta-calculation pass SHALL only be executed when `hit_zones ~= nil and Options.osd_interactivity == true`.

## Capabilities

### New Capabilities
- *(none)*

### Modified Capabilities
- `subtitle-rendering`: The gap-calculation rule for OSD inter-subtitle spacing now explicitly specifies that the **previous** subtitle's font size drives the gap, not the current one.
- `osd-hit-zone-sync`: The condition under which hit-zone geometry is computed must be aligned with the `osd_interactivity` flag to avoid redundant work.

## Impact

- **File**: `scripts/lls_core.lua` — `draw_drum` function and `calculate_osd_line_meta` function only.
- **No API changes**: All option names and FSM fields remain unchanged.
- **No behavioral change for normal content**: Regressions are only observable when `drum_active_size_mul != drum_context_size_mul` (active line is larger/smaller than context lines).
- **Performance**: Eliminates redundant `dw_get_str_width` calls on every render tick for non-interactive mode.
