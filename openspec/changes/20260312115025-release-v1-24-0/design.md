## Context

Previously, searching was an informal part of the Drum Window and lacked robust input handling or synchronized jumping. This release treats search as a core, standalone capability required for efficient language acquisition.

## Goals / Non-Goals

**Goals:**
- Provide a responsive search bar with multi-language support.
- Enable clipboard-to-search pasting.
- Ensure 1:1 synchronization between search jumps and video playback.

## Decisions

- **Standalone Overlay**: `search_osd` is separated from `draw_dw` to allow summoning the search bar from anywhere.
- **Input Logic**: The script captures `any_key` events into a buffer. It uses specific UTF-8 byte-length checks to handle Russian characters and backspacing correctly.
- **Clipboard Bridge**: Since Lua's native `io.popen` is available, the script executes `powershell -NoProfile -Command Get-Clipboard` to retrieve text. This is mapped to `Ctrl+V` and `Ctrl+М`.
- **Sync Seek**: To prevent the "subtitle lag" common in multi-track mpv playback, all search-based navigation is executed via `mp.commandv("seek", target_time, "absolute", "exact")`.
- **Dropdown Hit-Testing**: The search results are rendered as a vertical list. The script maps OSD Y-coordinates to the list indices to enable mouse selection.

## Risks / Trade-offs

- **Risk**: Performance impact of fuzzy searching on very large subtitle files.
- **Mitigation**: The search algorithm is optimized for rapid string-matching and only updates when the query buffer changes.
