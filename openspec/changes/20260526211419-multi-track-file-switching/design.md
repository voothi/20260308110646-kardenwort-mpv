## Context

Language learners frequently work with media where localized dubs or multi-track options are distributed across distinct companion video files in the same folder instead of being multiplexed inside a single MKV/MP4 container. For example, a main video `video.mp4` might have sibling files `video.ru.mp4` (Russian dub) and `video.de.mp4` (German dub). 

Currently, there is no way for a user to switch between these separate companion files without stopping playback, losing their location/speed, and breaking their immersion. This design details the mechanism to dynamically discover these companion files, load them seamlessly, and perfectly preserve all active playback states.

## Goals / Non-Goals

**Goals:**
- Automatically scan the active media directory using MPV's native filesystem APIs to index language-postfix companion files.
- Seamlessly swap the active file at runtime when the hotkey (`Shift+3`, `SHARP`, or `№`) is triggered.
- Unified keybinding: If companion files exist in the directory, cycle companion files. Otherwise, fall back to standard internal multiplexed audio track cycling (using GBoard-style double-tap switching).
- Guarantee 100% preservation of the active `time-pos`, `speed`, and `pause` state during swaps.
- Deliver themed HUD visual feedback showing the active companion track's language code.

**Non-Goals:**
- Dynamically mixing/merging audio-only files with the main video file at runtime.
- Merging files together on disk.

## Decisions

### 1. File Discovery & Indexing
- **Decision**: We will use MPV's native `utils.readdir(dir, "files")` to scan the folder of the active media file.
- **Rationale**: Avoids sub-process invocation lag and OS-specific command dependencies, ensuring a highly performant and cross-platform (Windows/Linux) solution.
- **Implementation**: On media load, we extract the directory and base filename. We match files in the directory that start with `<base>` and end with `<ext>`, and parse any intermediate postfix (e.g. `video.ru.mp4` matches `<base>=video`, `<postfix>=ru`, `<ext>=mp4`).

### 2. State-Preserving Swapping
- **Decision**: Swapping will capture `time-pos`, `speed`, and `pause` state before invoking `loadfile next_path replace start=<time>`.
- **Rationale**: MPV's `loadfile` replaces the current track. Passing the `start=<time>` argument ensures immediate seeking on load. Re-applying `speed` and `pause` state immediately after loading guarantees continuity.

### 3. Keybindings & Hybrid Selector
- **Decision**: Bind the unified switching logic to `Shift+3`, `SHARP`, and `№` (mapping to `cycle-audio` in `input.conf`).
- **Rationale**: Keeps a single primary layout-safe hotkey for all audio cycling operations. If multiple companion files are discovered in the workspace directory, we intercept the command to swap physical files. If not, we fall back to multiplexed tracks.

## Risks / Trade-offs

- **[Risk] Slower loading times for large video files** $\rightarrow$ **[Mitigation]** Use `replace` mode in `loadfile` which preserves active decoder instances where possible, and utilize MPV's native caching mechanisms.
- **[Risk] Postfix collision** (e.g., `video.part1.mp4` treated as a language track `part1`) $\rightarrow$ **[Mitigation]** Keep the mapping flexible and display whatever postfix is found in the themed OSD, allowing the user to cycle through them naturally.
