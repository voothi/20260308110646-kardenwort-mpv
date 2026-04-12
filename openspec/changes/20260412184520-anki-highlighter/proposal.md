## Why

Language learners use MPV to immersive themselves in target languages, but building Anki flashcards directly from subtitles is currently separate or highly cumbersome. A mechanism to visually highlight text and seamlessly export those specific "Terms" and "Quotes" with contextual bounds directly to a TSV database would bridge the gap between media consumption and active vocabulary acquisition.

## What Changes

- Implement a mechanism (`MBTN_MID`) in the Drum Window to commit selected words/substrings to a TSV database for Anki import.
- Overlay dynamically calculated colors onto the subtitle script based on the overlap depth of highlighted passages (e.g., compounding intensity if a Term is highlighted within a Quote).
- Implement configurable context boundaries mapping directly to TSV headers to extract the whole sentence without capturing unrelated surrounding text.
- Introduce an instantaneous toggle (`h` / `р` layout) to choose whether highlights are rendered globally throughout the video or locally at their exact creation timestamp.
- Add robust parsing layer to reload the TSV dictionary when the video is loaded, enabling seamless edit/restore capacity across sessions.

## Capabilities

### New Capabilities
- `anki-highlighting`: A local database to track and render interactive vocabulary marks and sentence mining definitions within the player.

### Modified Capabilities
- `drum-window`: Enhancing the `w` drum window state machine to include highlighting interaction and extraction bindings (`MBTN_MID`).
- `subtitle-rendering`: Modifying the main subtitle renderer to consume the Anki map and inject compound color ASS tags efficiently.

## Impact

- **lls_core.lua**: Extensive enhancements to the `FSM` state handling, file I/O operations for TSV, and text processing/ASS manipulation during subtitle render logic.
- **mpv.conf / input.conf**: Registration of new configurations for colors, TSV structures, bounds, and new binding configurations for interactions.
- **Video Directory**: Creates and mutates `<video_name>.tsv` files corresponding to currently played media.
