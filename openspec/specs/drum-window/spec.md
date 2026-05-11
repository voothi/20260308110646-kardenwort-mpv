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

### Requirement: Drum Window Selection Priority
The system SHALL prioritize the preservation of the active word pointer (Yellow Highlight) when opening the Drum Window and ensure the viewport alignment matches the cursor.

#### Scenario: Visual Cursor Sync (Pointer Jump)
- **WHEN** a mouse-based interaction occurs (e.g., clicking on a word with a pairing modifier)
- **THEN** the system SHALL immediately synchronize the Drum Window cursor (Yellow Highlight) and the anchor point to the word under the mouse pointer.
- **AND** this synchronization SHALL occur before the specific action logic (e.g., toggling) is executed.
- **AND** the sticky horizontal navigation anchor (`FSM.DW_CURSOR_X`) SHALL be reset to ensure the next keyboard movement re-anchors to the new cursor position.

#### Scenario: Opening Drum Window with active Pointer
- **GIVEN** a word is already highlighted in Drum Mode (C) or Regular SRT mode.
- **WHEN** the user opens the Drum Window (Mode W).
- **THEN** the system SHALL NOT reset the pointer.
- **AND** the word SHALL remain highlighted at the same index in the window.
- **AND** the window viewport (`FSM.DW_VIEW_CENTER`) SHALL immediately jump to the line containing the pointer.

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

### Requirement: Configurable Jump Distances
The Drum Window SHALL allow users to customize the jump distances for boosted navigation (Ctrl+Arrows) via script options.

#### Scenario: Custom Jump Increments
- **WHEN** the user configures `dw_jump_words` or `dw_jump_lines` in `mpv.conf`
- **THEN** the system SHALL apply these increments to the corresponding keyboard navigation commands.
- **AND** a `Ctrl+RIGHT` press SHALL move the cursor by the number of words specified in `dw_jump_words`.

### Requirement: Line-Specific Alpha in Drum Window
The system SHALL apply different transparency levels to the "active" subtitle line vs "context" subtitle lines within the Drum Window.

#### Scenario: Visual Emphasis in Window Mode
- **WHEN** the Drum Window is displayed.
- **AND** `dw_active_opacity` is "00" and `dw_context_opacity` is "30".
- **THEN** the active playback line (indicated by `FSM.DW_ACTIVE_LINE`) SHALL be fully opaque.
- **AND** all other lines in the window SHALL be rendered with "30" alpha (semi-transparent).

### Requirement: Configurable Fading
The transparency levels for active and context lines in the Drum Window MUST be user-configurable via standard script options.

#### Scenario: Disabling fading
- **WHEN** the user sets `dw_context_opacity` to "00" in `mpv.conf`.
- **THEN** all lines in the Drum Window SHALL be rendered with full saturation, matching the previous behavior.

### Requirement: OSD-Agnostic Track Loading
The system SHALL index all dialogue lines from external subtitle files regardless of their character set or language, ensuring that both primary and secondary tracks are fully resident in memory.

#### Scenario: Loading Russian ASS Translation
- **WHEN** an ASS subtitle track containing Cyrillic characters is loaded.
- **THEN** the system SHALL NOT filter out these lines during the ingestion phase.
- **AND** the Tracks.sec.subs table SHALL contain all dialogue entries for use in translation copy and tooltip rendering.

### Requirement: Tooltip Content Rendering
The Drum Window translation tooltip SHALL render secondary subtitles with full highlight synchronization, mirroring the selection state of the primary track.

#### Scenario: Selection Sync in Tooltip
- **GIVEN** a word or range is highlighted in Yellow or Pink in the Drum Window.
- **WHEN** the tooltip (E) is displayed for the corresponding line.
- **THEN** the secondary tokens in the tooltip SHALL be rendered with the same colors and bold styling as their primary counterparts, provided they share the same logical index.
- **AND** the highlighting SHALL be "surgical," preserving the base color of punctuation and whitespace.

### Requirement: Non-Cyclic Esc Handler
The `Esc` key handler MUST prioritize clearing selections and pointers over closing the Drum Window state.

#### Scenario: Clearing a Multi-Word Selection
- **WHEN** a yellow range selection is active and `Esc` is pressed
- **THEN** the selection MUST be cleared, but the Drum Window MUST remain active.

### Requirement: Staged Reset Hierarchy
The `Esc` key MUST follow a strict staged hierarchy for clearing state:
1. Stage 1: Clear Pending Set (Pink).
2. Stage 2: Clear Range Selection (Yellow).
3. Stage 3: Full Pointer Reset & Cursor Synchronization.

### Requirement: Post-Export Selection Reset
The system MUST automatically perform a full selection reset (equivalent to Stage 3 of the Esc handler) immediately after a successful Anki export operation.

#### Scenario: Saving a Single Word
- **WHEN** the user saves a word via the `g` key
- **THEN** the yellow selection range and pointer MUST be cleared upon successful export.

#### Scenario: Saving a Paired Set
- **WHEN** the user saves a pink paired set via the `f` key
- **THEN** the entire paired set AND the active yellow selection MUST be cleared.

### Requirement: Drum Window Input Blocking
Subtitle positioning controls MUST be intercepted and suppressed when the Drum Window is active to prevent accidental visual disruption of the high-precision interface.

#### Scenario: Pressing positioning keys while Drum Window is open
- **WHEN** the Drum Window is active (`FSM.DRUM_WINDOW ~= "OFF"`)
- **AND** the user attempts to adjust subtitle positioning (e.g., `r`, `t`, `R`, `T`)
- **THEN** the system SHALL display "X".

### Requirement: Unified Drum Window Management Inscriptions
The system SHALL provide consistent feedback when global keys that are managed or suppressed by the Drum Window are pressed.

#### Scenario: Pressing managed global keys in DW mode
- **WHEN** the Drum Window is active (`FSM.DRUM_WINDOW ~= "OFF"`)
- **AND** the user presses any of the following keys: `x`, `Shift+x`, `c`, `Shift+c`, `Shift+f`
- **THEN** the system SHALL display a "X" OSD message.
- **AND** the default action for these keys SHALL be suppressed.

#### Scenario: Pressing Pause Mode toggle (Shift+f) on non-ASS tracks
- **WHEN** the user presses `Shift+f`
- **AND** the active subtitle track is NOT an ASS file (`FSM.MEDIA_STATE` does not contain "ASS")
- **THEN** the system SHALL display a "X" OSD message.
- **AND** the Pause Mode SHALL NOT be toggled.

### Requirement: Cross-Mode Cursor Synchronization
The sequential Escape mechanism SHALL be applied uniformly in both Drum Mode (Mode C) and Drum Window (Mode W).

#### Scenario: Escape synchronization in Mode C (Refined)
- **WHEN** Drum Mode (Mode C) is ON and the Drum Window (Mode W) is OFF
- **WHEN** A selection (Pink, Yellow Range, or Pointer) exists and the user presses `Esc`
- **THEN** The system SHALL evaluate and clear states in sequential order.
- **AND** When the final Yellow Pointer is cleared, `FSM.DW_CURSOR_LINE` MUST be synchronized with the currently active playback line index.

### Requirement: Independent Mode C Viewport
The cursor navigation in Mode C MUST NOT trigger viewport scrolling.

#### Scenario: Moving cursor in Mode C
- **WHEN** The user navigates the cursor with arrows in Mode C
- **THEN** The yellow indicator moves but the underlying subtitles stay fixed at the current video playback position.

### Requirement: Two-Screen Interaction Controls
The system SHALL provide granular toggles to independently control the Primary (Screen 1) and Secondary (Screen 2) tracks for both **Interactivity** and **Highlighting** across all viewing modes (DW, Drum, SRT).
- **Primary Track (Screen 1)**: Controlled via `*_pri_interactivity` and `*_pri_highlighting`.
- **Secondary Track (Screen 2)**: Controlled via `*_sec_interactivity` and `*_sec_highlighting`.
- **Global Master**: `osd_interactivity` SHALL act as the final gate for all mouse-based subtitle interaction.

### Requirement: Aesthetic Parity Standard
Secondary subtitles (including the Tooltip) SHALL be visually consistent with the primary track while maintaining specialized readability:
- **Background Color**: SHALL default to `000000` (Black) to ensure contrast parity.
- **Border Weight**: SHALL be calibrated to `1.2` for secondary tracks to normalize mono-spaced Cyrillic visual weight.

### Requirement: No-Stub Verification
Every parameter exposed in the configuration (e.g., `mpv.conf`) SHALL be fully wired to its respective logic in the rendering and interaction pipeline. Hardcoded values that bypass user-configured options are prohibited.

### Requirement: Flattened Hit-Testing Architecture
To ensure high-performance interaction on dual-track OSDs, the hit-testing pipeline SHALL follow a flattened, track-aware model:
- **Zone Tagging**: OSD hit-zones SHALL be explicitly tagged with an `is_pri` flag during generation.
- **O(1) Dispatching**: The global hit-test dispatcher SHALL use this flag to perform flat filtering against interactivity toggles, avoiding expensive secondary search loops or post-hit investigations.

### Requirement: Stability and Error Prevention
The system MUST NOT crash when toggling modes or updating the OSD.

#### Scenario: Opening DW Mode
- **WHEN** The user toggles the DW Mode (Mode W) ON
- **THEN** The window must initialize and render without Lua errors, even if it's the first render of the session.
- **AND** The system SHALL display "Drum Window: ON".

#### Scenario: Closing DW Mode
- **WHEN** The user toggles the DW Mode (Mode W) OFF
- **THEN** The system SHALL display "Drum Window: OFF".
