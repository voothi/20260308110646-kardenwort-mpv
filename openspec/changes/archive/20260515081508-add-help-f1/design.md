## Context
Kardenwort lacks an in-player help system. Users often forget specialized shortcuts (e.g., `Shift+R/T` for positioning or `Ctrl+F` for search). While `input.conf` documents these, user customizations in `mpv.conf` can override them.

## Goals / Non-Goals

**Goals:**
- Implement a dedicated Help HUD overlay.
- Dynamic key resolution using `Options` table and `mp.get_property_native("input-bindings")`.
- Categorized display of shortcuts.
- Visual consistency with existing Search and Drum Window HUDs.

**Non-Goals:**
- Interactive binding editing.
- Full-screen documentation browser.

## Decisions

### 1. Help HUD Implementation
- Use `mp.create_osd_overlay("ass-events")` for the help screen.
- A central function `cmd_toggle_help()` will manage the visibility of the overlay.
- The overlay will use the same background styling as the Drum Window (semi-transparent black).

### 2. Dynamic Key Discovery
- Instead of hardcoding strings like "Press S for Autopause", the script will look up `Options.dw_key_...` and search through `input-bindings` to find the actual mapped key for specific script-messages or script-bindings.
- This ensures that if a user maps `kardenwort/toggle-autopause` to `P` instead of `S`, the help screen shows `P`.

### 3. Layout and Categorization
- Group shortcuts into logical blocks:
    - **Global / Playback**: Smart Space, Autopause, Replay.
    - **Navigation**: Prev/Next Subtitle, Seek Time.
    - **Drum / Reading Mode**: Toggles, Book Mode, Context Copy.
    - **Search HUD**: Toggles, Internal Navigation.
    - **Anki / Mining**: Export, Open Record, Highlighting.
- Each block will have a header and a table-like list of key-action pairs.

### 4. Trigger Mechanism
- Global binding for `F1`.
- Russian layout counterpart: `F1` (typically same physical key).

## Risks / Trade-offs

- **OSD Size**: A comprehensive list might exceed the screen height. 
    - *Mitigation*: Use a multi-column layout or scrollable OSD (though mpv OSD scrolling is limited, multi-column is better).
- **Binding Complexity**: Some actions might have multiple keys.
    - *Mitigation*: Show the primary key or a list of mapped keys for the action.
