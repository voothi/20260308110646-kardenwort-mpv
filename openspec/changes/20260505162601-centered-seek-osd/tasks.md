## 1. Configuration Expansion

- [x] 1.1 Expand `Options` in `lls_core.lua` with `seek_font_name`, `seek_font_size`, `seek_font_bold`, `seek_color`, `seek_bg_color`, `seek_bg_opacity`, `seek_border_size`, `seek_shadow_offset`
- [x] 1.2 `seek_time_delta` and `seek_osd_duration` are already present
- [x] 1.3 Add all new styling options to `mpv.conf` with `script-opts-append`

## 2. Directional OSD Implementation

- [x] 2.1 Update `show_osd_center` to `show_seek_osd(msg, alignment)` in `lls_core.lua`
- [x] 2.2 Implement directional logic: `-` seeks use `{\an4}`, `+` seeks use `{\an6}`
- [x] 2.3 Apply the new `Options.seek_*` styling parameters to the OSD message string

## 3. Script-Driven Seeking (Refinement)

- [x] 3.1 `cmd_seek_time(delta)` and script bindings are already present
- [x] 3.2 Update `cmd_seek_time` to call the new `show_seek_osd` with correct alignment

## 4. Layout Verification

- [x] 4.1 Key bindings in `input.conf` are already updated
- [x] 4.2 Verify that Russian keys (`Ф`, `В`) correctly trigger the directional OSD
