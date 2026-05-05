# Tasks: Directional Seek OSD

**ID**: 20260505162601-centered-seek-osd
**ZID**: 20260505201004

## 1. Directional OSD & Positioning

- [x] 1.1 Implement `show_seek_osd` with `alignment` parameter (`4` for LEFT, `6` for RIGHT).
- [x] 1.2 Create a dedicated OSD overlay (`seek_osd`) with 1080p-relative resolution (`Options.font_base_height`).
- [x] 1.3 Implement vertically centered positioning (`cy = Options.font_base_height / 2`).

## 2. Granular Styling Parameters

- [x] 2.1 Add styling options (`seek_font_name`, `seek_font_size`, `seek_color`, etc.) to the `Options` table.
- [x] 2.2 Expose styling parameters in `mpv.conf` via `script-opts-append`.
- [x] 2.3 Ensure the OSD uses these parameters via ASS tag formatting.

## 3. YouTube-Style Accumulator Logic

- [x] 3.1 Implement session-based accumulation in `cmd_seek_time`.
- [x] 3.2 Add direction-change reset: Reset accumulator if `dir` flips during a session.
- [x] 3.3 Implement table-based `gsub` template engine for `%p`, `%v`, `%P`, `%V` placeholders.
- [x] 3.4 Support `seek_msg_format` and `seek_msg_cumulative_format` in `mpv.conf`.

## 4. Architectural Cleanup & Reliability

- [x] 4.1 Fix Lua scope errors by correctly ordering forward declarations of UI objects.
- [x] 4.2 Fix nil-value errors for newly introduced styling options (e.g., `seek_shadow_offset`).
- [x] 4.3 Unify resolution settings across all immersion engine overlays to respect `Options.font_base_height`.

## 5. Verification

- [x] 5.1 Verify that single seeks show the standard format (`+2`).
- [x] 5.2 Verify that rapid consecutive seeks show the cumulative total (`+4`, `+6`).
- [x] 5.3 Verify that switching direction (LEFT/RIGHT) starts a new counter.
- [x] 5.4 Confirm that styling (size, color) correctly follows `mpv.conf` overrides.
