# Drum Window (Mode W)

## Purpose
Provide a high-precision, index-based interface for subtitle reading, selection, and mining with persistent highlight feedback.
## Requirements
### Requirement: Drum Window Unified Styling
The Drum Window SHALL allow explicit control over its appearance (font name, size, weight/boldness, and background transparency) via script options.

#### Scenario: Background Opacity Alignment
- **WHEN** the `dw_bg_opacity` and `dw_text_opacity` configurations are adjusted
- **THEN** the system SHALL apply the corresponding Alpha values (`\4a` and `\1a`) to the Window's localized background boxes and text respectively.

#### Scenario: Visual Normalization
- **WHEN** the user configures `dw_font_size`, `dw_border_size`, or `dw_shadow_offset`
- **THEN** the Drum Window SHALL apply these precisely to the rendering block, allowing the user to visually normalize the monospace interface to match the proportional Drum Mode interface.

#### Scenario: Unified Font and Weight
- **WHEN** the user configures `dw_font_name` or `dw_font_bold`
- **THEN** the Drum Window SHALL apply these font and weight settings to the text rendering, ensuring a consistent aesthetic across all mpv UI layers.

### Requirement: Scroll-Aware Selection Continuity
The Drum Window SHALL ensure that any active text selection, word-highlight, or the focus cursor position is preserved and correctly synchronized when the viewport is scrolled or when interacting with different input layouts.

#### Scenario: Wheel Scroll Selection Stability
- **WHEN** the user is actively dragging the mouse to select text (MBTN_LEFT down)
- **AND** the user scrolls the mouse wheel (WHEEL_UP or WHEEL_DOWN)
- **THEN** the system SHALL immediately update the selection range to include the word now under the mouse cursor at its new viewport position.
- **AND** the selection SHALL NOT be cleared or disrupted by the scroll event.

#### Scenario: Visual Cursor Sync (Pointer Jump)
- **WHEN** a mouse-based interaction occurs (e.g., clicking on a word with a pairing modifier)
- **THEN** the system SHALL immediately synchronize the Drum Window cursor (Yellow Highlight) and the anchor point to the word under the mouse pointer.
- **AND** this synchronization SHALL occur before the specific action logic (e.g., toggling) is executed.
- **AND** the sticky horizontal navigation anchor (`FSM.DW_CURSOR_X`) SHALL be reset to ensure the next keyboard movement re-anchors to the new cursor position.

### Requirement: Exclusive UI Visibility
The Drum Window SHALL maintain exclusive visibility over the active subtitle information, ensuring that native mpv subtitles do not overlap or leak through the UI regardless of media state changes or external property resets.

#### Scenario: Persistent Suppression During Track Selection
- **WHEN** the Drum Window is active (`FSM.DRUM_WINDOW ~= "OFF"`)
- **AND** a subtitle track change or media state update occurs (e.g., SID change)
- **THEN** the system SHALL immediately ensure and maintain that `sub-visibility` and `secondary-sub-visibility` are set to `false`.
- **AND** native subtitle rendering SHALL NOT be restored until the Drum Window is explicitly closed.

### Requirement: Drum Window Observer Resilience
The system SHALL wrap all `mp.observe_property` callbacks that invoke `update_media_state` in `pcall` so that a Lua error inside that function does not cause mpv to silently drop the observer. If an observer error occurs, the error message SHALL be written via `print()` to ensure visibility in the terminal regardless of mpv's configured log level.

#### Scenario: Observer callback crashes during subtitle load
- **WHEN** `update_media_state` throws a Lua error while processing a track change
- **AND** the error occurs inside an `mp.observe_property` callback
- **THEN** the observer SHALL remain registered and continue firing on future property changes
- **AND** the error SHALL be printed to the terminal as `[LLS ERROR] ...`

### Requirement: Drum Window Force Refresh on Open
When transitioning from `OFF` to `DOCKED` state, the system SHALL call `load_anki_tsv(true)` before any state mutation, so that mid-session file deletions are reflected at the exact moment the user opens the window rather than waiting for the next periodic timer cycle.

#### Scenario: File deleted before opening Drum Window
- **WHEN** the `.tsv` file is deleted while mpv is running
- **AND** the user presses the Drum Window toggle before the 5-second timer fires
- **THEN** the window SHALL open with an empty highlights table
- **AND** no phantom highlights from the deleted file SHALL be visible

### Requirement: Drum Window Opens Without TSV
The Drum Window SHALL open and render subtitle content normally even when no `.tsv` record file exists. An absent TSV file results in an empty highlights table, which is a valid state. The system SHALL NOT block the window transition based on the size of the highlights table.

#### Scenario: No TSV file present
- **WHEN** no `.tsv` file exists for the current media
- **AND** the user presses the Drum Window toggle
- **THEN** the window SHALL open in `DOCKED` state
- **AND** subtitle lines SHALL render without any saved-word highlights
- **AND** all Drum Window key bindings SHALL be active and functional

### Requirement: Multi-Input Pairing Persistence
The Drum Window SHALL maintain a persistent "Paired Selection" set (indicated by Pink highlight) that persists across multiple interaction events and is independent of the standard Yellow selection range.

#### Scenario: Persistence Across Modifier Release
- **WHEN** words are added to the paired selection set while holding a modifier key (e.g., Ctrl)
- **AND** the user releases the modifier key
- **THEN** the paired selection set (Pink highlights) SHALL NOT be cleared.

#### Scenario: Explicit Paired Set Discard
- **WHEN** the user triggers the explicit discard command (e.g., Ctrl+ESC)
- **THEN** the entire pending paired selection set SHALL be cleared immediately.

### Requirement: Range-Aware Paired Selection
The Drum Window SHALL allow a contiguous yellow selection range to be converted into a discrete paired selection set in a single action.

#### Scenario: Drag-to-Pair (Mouse)
- **WHEN** the user drags a selection using a mouse-based pairing shortcut (e.g., Ctrl+MBTN_LEFT)
- **THEN** the system SHALL render a standard yellow selection range during the drag.
- **AND** upon release, the system SHALL convert every word in that range into the pink paired selection set and clear the temporary yellow selection.

#### Scenario: Select-then-Toggle (Keyboard)
- **WHEN** a yellow selection range is active
- **AND** the user triggers the pairing toggle command (e.g., `t`)
- **THEN** the system SHALL convert the entire yellow range into the pink paired selection set.

### Requirement: Multi-Input Jitter Resilience
The system SHALL prioritize explicit keyboard navigation over implicit mouse activity when both occur in a narrow temporal window to ensure 100% stability for remote control devices.

#### Scenario: Mouse Interaction Shielding
- **WHEN** any keyboard-bound Drum Window shortcut (e.g., `t`) is triggered
- **THEN** the system SHALL activate an interaction shield (`FSM.DW_MOUSE_LOCK_UNTIL`) that ignores all incoming mouse button events for a duration defined by `Options.dw_mouse_shield_ms` (Default: 150ms).
- **AND** this shield SHALL prevent accidental hardware "ghost clicks" from moving the yellow focus cursor or disrupting the active selection.

