## MODIFIED Requirements

### Requirement: Drum Window Unified Styling
The Drum Window SHALL allow explicit control over its appearance (font name, size, weight/boldness, and background transparency) via script options, matching the parameters of other rendering modes (SRT, Drum, Tooltip).

#### Scenario: Background Opacity Alignment
- **WHEN** the `dw_bg_opacity` and `dw_text_opacity` configurations are adjusted
- **THEN** the system SHALL apply the corresponding Alpha values (`\4a` and `\1a`) to the Window's localized background boxes and text respectively.

#### Scenario: Visual Normalization
- **WHEN** the user configures `dw_font_size`, `dw_border_size`, or `dw_shadow_offset`
- **THEN** the Drum Window SHALL apply these precisely to the rendering block, allowing the user to visually normalize the monospace interface to match the proportional Drum Mode interface.

#### Scenario: Unified Font and Weight
- **WHEN** the user configures `dw_font_name` or `dw_font_bold`
### Requirement: Scroll-Aware Selection Continuity
The Drum Window SHALL ensure that any active text selection or word-highlight state is preserved and correctly synchronized when the viewport is scrolled using the mouse wheel.

#### Scenario: Wheel Scroll Selection Stability
- **WHEN** the user is actively dragging the mouse to select text (MBTN_LEFT down)
- **AND** the user scrolls the mouse wheel (WHEEL_UP or WHEEL_DOWN)
- **THEN** the system SHALL immediately update the selection range to include the word now under the mouse cursor at its new viewport position.
- **AND** the selection SHALL NOT be cleared or disrupted by the scroll event.

#### Scenario: Stationary Active Highlight
- **WHEN** the Drum Window is scrolled via mouse wheel while NOT dragging
- **THEN** the system SHALL maintain the highlight on the specific text index previously selected.
- **AND** the highlight SHALL NOT snap to the word currently under the mouse pointer.
- **AND** the cursor state (`FSM.DW_CURSOR_WORD`) SHALL NOT be reset to an invalid state.

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
