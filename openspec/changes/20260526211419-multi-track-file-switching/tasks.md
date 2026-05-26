## 1. Companion Discovery & Parsing

- [ ] 1.1 Extract directory, prefix, and extension of active media file in main.lua
- [ ] 1.2 Implement a directory scanning function using utils.readdir
- [ ] 1.3 Implement parser to detect and group files with matching prefix/extension but different language postfixes

## 2. State-Preserving Swapping Engine

- [ ] 2.1 Write cmd_cycle_companion function that gets current time-pos, speed, and pause state
- [ ] 2.2 Execute loadfile replace with time parameter
- [ ] 2.3 Restore speed and pause state after replacement

## 3. UI/OSD & Configuration

- [ ] 3.1 Bind cycle-companion command to Shift+4 and $ in input.conf
- [ ] 3.2 Add Shift+4 / $ cycle-companion reference to F1 HELP_SCHEMA
- [ ] 3.3 Show premium themed OSD notice card showing active companion file language
- [ ] 3.4 Document new capability in README.md and add option in mpv.conf
