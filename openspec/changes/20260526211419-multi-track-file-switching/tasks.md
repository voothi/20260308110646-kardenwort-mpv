## 1. Companion Discovery & Parsing

- [x] 1.1 Extract directory, prefix, and extension of active media file in main.lua
- [x] 1.2 Implement a directory scanning function using utils.readdir
- [x] 1.3 Implement parser to detect and group files with matching prefix/extension but different language postfixes

## 2. Companion Audio Attachment Engine

- [x] 2.1 Integrate directory scanning into cmd_cycle_audio to discover companion audio providers
- [x] 2.2 Attach missing companion audio tracks using MPV external audio APIs (no loadfile replace)
- [x] 2.3 Keep one unified Shift+3 cycle flow via `aid` for internal and companion audio tracks

## 3. UI/OSD & Configuration

- [x] 3.1 Keep keybindings bound to Shift+3, SHARP, and № for cycle-audio layout-safely in input.conf
- [x] 3.2 Ensure F1 HELP_SCHEMA includes the unified Cycle Audio Track mapping
- [x] 3.3 Show premium themed OSD notice card showing active audio label (e.g. Audio: RU)
- [x] 3.4 Document new capability in README.md and add option in mpv.conf
