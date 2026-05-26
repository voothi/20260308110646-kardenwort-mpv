## 1. Companion Discovery & Parsing

- [x] 1.1 Extract directory, prefix, and extension of active media file in main.lua
- [x] 1.2 Implement a directory scanning function using utils.readdir
- [x] 1.3 Implement parser to detect and group files with matching prefix/extension but different language postfixes

## 2. State-Preserving Swapping Engine

- [x] 2.1 Integrate directory scanning and swapping logic into cmd_cycle_audio to dynamically intercept audio switches when companion files are present
- [x] 2.2 Execute loadfile replace with time parameter when multiple companion files are detected
- [x] 2.3 Restore speed and pause state after replacement

## 3. UI/OSD & Configuration

- [x] 3.1 Keep keybindings bound to Shift+3, SHARP, and № for cycle-audio layout-safely in input.conf
- [x] 3.2 Ensure F1 HELP_SCHEMA includes the unified Cycle Audio Track mapping
- [x] 3.3 Show premium themed OSD notice card showing active companion file language (e.g. Track: RU)
- [x] 3.4 Document new capability in README.md and add option in mpv.conf
