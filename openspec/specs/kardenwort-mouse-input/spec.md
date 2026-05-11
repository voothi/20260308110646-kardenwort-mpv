# kardenwort-mouse-input Specification

## Purpose
Provide a robust, high-precision mouse interaction model for the Drum Window that accommodates hardware jitter (ghost clicks), minimalist input devices (remote controls), and variable viewport scrolling.
## Requirements
### Requirement: Systemic Interaction Shield Lockout
The interaction engine SHALL enforce a uniform 150ms lockout for all mouse events following a keyboard-based interaction, governed by a single configurable parameter (`Options.dw_mouse_shield_ms`).
- **Interaction Shielding**: All navigational and input handlers (Arrows, Enter, a/d, Double-Click Seek, etc.) MUST set `FSM.DW_MOUSE_LOCK_UNTIL = mp.get_time() + (Options.dw_mouse_shield_ms / 1000)`.
- **Efficacy**: Mouse button events (press, up, drag) and passive pointer synchronization (hover/sync) SHALL be ignored if the current time is less than `FSM.DW_MOUSE_LOCK_UNTIL`.
- **Hardcoded Constants**: Hardcoded durations for lockout are STRONGLY DISCOURAGED.

#### Scenario: Keyboard command triggers shield
- **WHEN** the user presses 'Arrow Down'
- **THEN** the system SHALL set the mouse lock using the value from `dw_mouse_shield_ms`.
- **AND** subsequent mouse clicks SHALL be ignored for at least that duration.

#### Scenario: Modifier-Exempt Responsiveness
- **WHEN** the user presses a standalone modifier key (Ctrl, Shift, Alt, Meta).
- **THEN** the system SHALL NOT trigger the mouse lock.
- **AND** mouse + keyboard combinations (e.g., Ctrl+Click) SHALL remain fully responsive.

### Requirement: Coordinate-Precise Sync (Pointer Jump Sync)
The system SHALL ensure the logical focus and highlight anchor are synchronized to the exact pixel-perfect word under the mouse pointer immediately *before* any action is dispatched.
- **Rationale**: Prevents actions from being applied to a previously "hovered" word if the pointer has jumped due to hardware latency.
- **Shield Constraint**: Synchronization logic SHALL be bypassed if an active Interaction Shield is in effect, preventing the pointer from "grabbing" new words during rapid UI transitions (like re-centering after a seek).

#### Scenario: Pointer jump synchronization
- **WHEN** the user initiates a click action
- **THEN** the system SHALL perform a final hit-test at the current mouse coordinates before processing the event.
- **AND** the logical focus SHALL be updated to match the word currently under the pointer.

### Requirement: Zero-Collapse Clamping
The hit-testing engine SHALL implement logical index clamping for margin and line gap areas.
- **Boundary Behavior**: Dragging into line gaps or past line ends SHALL snap the selection to the nearest boundary word's logical index.
- **Punctuation Support**: Clicks on punctuation or spaces SHALL NOT trigger "clamping" to a word if they have their own unique fractional logical index; they SHALL be selectable as discrete tokens.
- **Goal**: Prevent selection "collapse" or "breakage" caused by returning non-selectable visual token indices.

#### Scenario: Dragging into vertical margins
- **WHEN** the user drags the mouse into the vertical gap between lines
- **THEN** the hit-test SHALL return the logical index of the closest word on the adjacent line.
- **AND** the selection range SHALL remain contiguous.

### Requirement: Range-Locked Selection Protection
The system SHALL implement a "Protected Selection" state to prevent accidental collapse of existing multi-word selections during mouse interaction.
- **State Flag**: `FSM.DW_PROTECTED_SELECTION` (boolean).
- **Protection Logic**: When a mouse button press is initiated inside an already active selection range, the system SHALL set `FSM.DW_PROTECTED_SELECTION = true`.
- **Export Consistency**: If the protection flag is set, subsequent MMB release events SHALL commit the *existing* selection range to Anki, even if the mouse pointer has moved slightly.

#### Scenario: Clicking within an existing selection
- **WHEN** a multi-word selection is active
- **AND** the user clicks MMB inside that selection range
- **THEN** the existing selection SHALL NOT be cleared or modified.
- **AND** the whole range SHALL be exported upon button release.

### Requirement: Stream-Agnostic Initialization
Drum Window activation SHALL support internal and embedded subtitle streams that lack local file paths, provided subtitle segments are loaded in the engine's memory.

#### Scenario: Embedded Subtitle Support
- **WHEN** the user attempts to open the Drum Window (`w`).
- **AND** no external subtitle file path is detected (`pri.path` is nil).
- **BUT** subtitle segments are currently loaded in the engine's memory (`#pri.subs > 0`).
- **THEN** the system SHALL proceed with opening and rendering the Drum Window.

### Requirement: Mouse Motion Tracking
The system SHALL continuously track and evaluate the mouse position during Drum Window Mode.

#### Scenario: Pointer deviates from pinned line
- **WHEN** the user is dragging or simply moving the mouse without dragging
- **AND** the tooltip window layer relies on hover dynamics
- **THEN** the system SHALL actively supply `hit_test` events to the tooltip manager

### Requirement: RMB Interaction & Tooltip Pinning
The system SHALL bind `MBTN_RIGHT` dynamically within the Drum Window to manage informational tooltips.
- **Interaction**: Single-click on a word SHALL pin/unpin the tooltip.
- **Isolation**: RMB interactions MUST be isolated from the highlighting engine to prevent unwanted cursor changes during informational lookups.

#### Scenario: Tooltip Click Trigger
- **WHEN** in Drum Window Mode
- **THEN** `MBTN_RIGHT` SHALL dispatch drawing instructions to pin the tooltip 
- **AND** this explicit binding SHALL automatically deactivate when Window mode drops

### Requirement: Hover Mode Toggle
The system SHALL support a configurable hotkey to toggle Phase 2 "Hover Mode".

#### Scenario: User toggles Hover Mode using configured key
- **WHEN** the user is in Drum Window Mode
- **AND** the user presses the `dw_tooltip_hover_key` (e.g. `n`) mapped in configuration
- **THEN** the system SHALL swap `FSM.DW_TOOLTIP_MODE` between "CLICK" and "HOVER"

### Requirement: State-Aware Scroll Synchronization
The mouse input system SHALL ensure that viewport-altering events (scrolling) only synchronize the logical cursor state when an active user-initiated interaction (dragging) is in progress **AND the Drum Window is NOT OFF**.
- **Passive Scroll Stability**: Passive scrolling SHALL NOT update highlight coordinates based on mouse position.
- **Active Drag Sync**: Scrolling while holding a button SHALL continuously update hit-test coordinates.
- **Auto-scroll Guard**: The viewport auto-scroll mechanism SHALL be strictly disabled when `FSM.DRUM_WINDOW == "OFF"`.

#### Scenario: Auto-scroll suppressed in OSD mode
- **WHEN** the Drum Window is `OFF`
- **AND** the user clicks and holds the mouse button on a subtitle at the edge of the screen
- **THEN** the system SHALL NOT increment or decrement the selection cursor index.
- **AND** the selection range SHALL NOT expand beyond the initially clicked word or line.

### Requirement: Ctrl Modifier Key State Tracking
The mouse input system SHALL track the held/released state of the Ctrl key while the Drum Window is active, exposing a `ctrl_held` boolean for use by gesture dispatchers.

#### Scenario: Ctrl key state set on press
- **WHEN** the Drum Window is active
- **AND** the user presses the Ctrl key
- **THEN** the system SHALL set `ctrl_held = true`

#### Scenario: Ctrl key state cleared on release
- **WHEN** the Drum Window is active
- **AND** the user releases the Ctrl key
- **THEN** the system SHALL set `ctrl_held = false`
- **AND** the system SHALL emit a `ctrl-released` event.

### Requirement: Ctrl+LMB Gesture Routing
When `ctrl_held` is true, LMB press events SHALL be routed to the Ctrl-accumulator handler instead of the drag-selection handler.

#### Scenario: LMB with Ctrl held routes to accumulator
- **WHEN** the user presses LMB while `ctrl_held` is true
- **THEN** the word under the cursor SHALL be passed to the `ctrl_pending_set` toggle handler
- **AND** the drag-selection state machine SHALL NOT be entered.

### Requirement: Ctrl+MMB Gesture Routing
When `ctrl_held` is true, MMB press events SHALL be routed to the Ctrl-accumulator commit handler.

#### Scenario: MMB with Ctrl held routes to commit handler
- **WHEN** the user presses MMB while `ctrl_held` is true
- **THEN** the system SHALL pass the event to the `ctrl-multiselect` commit handler.

### Requirement: Gesture Routing (Warm vs. Cool)
The system SHALL distinguish between contiguous selection gestures and paired/accumulated selection gestures based on modifier state.
- **Warm Path (Contiguous)**: LMB/MMB without `Ctrl` -> Contiguous Drag/Selection.
- **Cool Path (Paired)**: Interactions with `Ctrl` (or specific Pairing keys) -> Addition to `ctrl_pending_set`.

#### Scenario: Warm path selection
- **WHEN** the user interacts with the mouse without holding Ctrl
- **THEN** the system SHALL treat the interaction as a standard word or range selection.

### Requirement: OSD Hit-Testing
The system SHALL implement a hit-testing mechanism for `drum_osd` that correctly identifies which word and subtitle index the mouse is hovering over, regardless of the screen resolution or aspect ratio.

#### Scenario: Mouse hovering over a word in Drum Mode
- **WHEN** Drum Mode is ON and the user hovers the mouse over a specific word in the OSD
- **THEN** the system SHALL identify the correct subtitle index and logical word index for that word

### Requirement: OSD Mouse Interaction
The system SHALL support mouse click and double-click events on the `drum_osd` overlay to trigger selection and seeking, mimicking the behavior of the Drum Window.

#### Scenario: Double-clicking a word in standard OSD
- **WHEN** standard OSD subtitles are active and the user double-clicks a word
- **THEN** the system SHALL seek to the start time of that subtitle and set the cursor focus to that word

### Requirement: Dynamic Position Synchronization
The OSD interaction logic SHALL automatically synchronize with changes to `sub-pos` and `secondary-sub-pos` without requiring a script reload.

#### Scenario: Adjusting subtitle position via hotkey
- **WHEN** the user presses `r` or `t` to move the subtitles vertically
- **THEN** the system SHALL immediately update the hit-zone metadata to reflect the new visual position of the words


### Requirement: OSD Vertical Proximity Snapping
The hit-testing engine SHALL implement vertical proximity snapping for Drum Mode (OSD) interactions to ensure parity with Drum Window behavior.
- **Snap Logic**: Mouse interactions occurring in the vertical gap between subtitle lines SHALL snap to the nearest line vertically, provided the cursor is horizontally aligned with that line's text bounds.
- **Threshold**: Snapping SHALL only occur if the vertical distance to the nearest line is within a reasonable proximity (e.g., 60 pixels), preventing accidental triggers from unrelated screen areas.

#### Scenario: Right-click in the gap between context lines in Drum Mode
- **WHEN** Drum Mode is ON
- **AND** the user right-clicks in the vertical gap between two visible subtitle lines
- **THEN** the system SHALL trigger the tooltip for the nearest word on the closest line.
- **AND** the interaction SHALL NOT be ignored.

#### Scenario: Click strictly between lines in Drum Mode
- **WHEN** in Drum Mode
- **AND** the user clicks LMB in the gap between lines
- **THEN** the system SHALL update the logical cursor to the nearest word vertically.

