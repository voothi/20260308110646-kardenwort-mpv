## 1. Script Foundation & State Management

- [x] 1.1 Create `scripts/resume_last_file.lua` with basic `opts` table and module requirements.
- [x] 1.2 Implement `save_last_file` function to persist media path to `~~/resume_session.state`.
- [x] 1.3 Register `file-loaded` and `shutdown` event handlers to trigger state saving.

## 2. Auto-Resume Logic

- [x] 2.1 Implement `mp.add_timeout` logic to check for empty startup (nil path and empty playlist).
- [x] 2.2 Add state file reading logic and file existence validation using `utils.file_info`.
- [x] 2.3 Implement the `loadfile` command execution for the validated last path.

## 3. Premium OSD Feedback System

- [x] 3.1 Implement sidecar subtitle detection using `utils.readdir` and filename matching.
- [x] 3.2 Add prioritized sorting logic to ensure `.en` (Main) tracks appear before `.ru` (Secondary).
- [x] 3.3 Build the multi-line vertical OSD message string (Filename + Subtitle list).
- [x] 3.4 Implement temporary `osd-font-size` property override to style the message without ASS tags.
- [x] 3.5 Add user-configurable options for `show_filename`, `show_subtitles`, `osd_font_size`, and `osd_duration`.
