## Why

The user requires a navigation style identical to reading a static book when exploring subtitles in the "Window Drum" (`w`) mode. Currently, actions like scrolling through subtitles (`a`, `d`) or looking up vocabulary via LMB double-click inadvertently kick the UI back to the regular Drum mode ("reel mode context"). This disrupts immersion and the logical reading flow by breaking the static centering of the Drum Window. The new "Book Mode" will allow locking the interface to Drum Window presentation temporarily or permanently, freezing the presentation center while navigating.

## What Changes

- Introduce a new "Book Mode" toggle via the `b` key (or its Russian equivalent `и`).
- Introduce a new configuration parameter in `mpv.conf` to permanently enable Book Mode.
- Suppress automatic fallback/transitions from Drum Window mode back to normal Drum mode when `a` (previous subtitle), `d` (next subtitle), or LMB double-click (vocabulary selection) are invoked, provided Book Mode is active.
- Lock subtitle positioning in absolute center layout when interacting within the locked Book Mode.

## Capabilities

### New Capabilities

- `book-mode-navigation`: Introduces the Book Mode interaction state and keybindings (`b`/`и`), configuration integration (`mpv.conf`), and suppression/override mechanisms for subtitle navigation triggers (`a`, `d`, LMB double-click) within the Window Drum mode.

### Modified Capabilities

<!-- Existing capabilities whose REQUIREMENTS are changing (not just implementation).
     Only list here if spec-level behavior changes. Each needs a delta spec file.
     Use existing spec names from openspec/specs/. Leave empty if no requirement changes. -->

## Impact

- State management in `kardenwort-mpv.lua` or relevant subtitle management modules will require a new boolean state for Book Mode.
- Input event handlers for `a`, `d`, `b` and `mbtn_left_dbl` need refactoring to intercept mode transitions conditionally based on the new state.
- `mpv.conf` parser will need an update to read the new default state boolean.
