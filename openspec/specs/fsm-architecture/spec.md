## Purpose

The FSM Architecture manages the unified state of the media player, coordinating subtitle visibility, operating modes, and feature boundaries to prevent race conditions and rendering conflicts.
## Requirements
### Requirement: Architecture and Subtitle Visibility Control Matrix
The system SHALL manage native and custom (OSD) subtitle visibilities via a unified Finite State Machine (FSM). `FSM.native_sub_vis` MUST act as the overarching source of desired truth for standard playback, but actual on-screen rendering MUST obey mutual exclusion rules between `native`, `DRUM`, and `DRUM_WINDOW`.

#### Scenario: User toggles Drum Window from Regular Playback
- **WHEN** user engages the Drum Window (`DRUM_WINDOW = 'DOCKED'`) while `FSM.DRUM = 'OFF'` and `FSM.native_sub_vis = true`
- **THEN** system SHALL snapshot the visibility state, forcefully set native visibility properties to false, clear the Drum regular OSD (if active via unified styling), and map Drum Window logic to the screen exclusively.

#### Scenario: User toggles Drum Window OFF
- **WHEN** user disengages the Drum Window
- **THEN** system SHALL restore the layout tracking variables to `FSM.DW_SAVED_SUB_VIS` and gracefully reinstate native or OSD-based SRT subtitle rendering based on that state without user interference.

### Requirement: Mode Mutually Exclusive Execution (Master Tick)
The system SHALL funnel all periodic updates through `master_tick()`. Only one primary subtitle rendering engine (Native, Drum Mode OSD, Drum Window OSD) SHALL draw to the screen at any given time.

#### Scenario: Master tick prevents native duplicate artefact
- **WHEN** the 0.05s periodic timer fires `master_tick()` and `FSM.DRUM_WINDOW == "OFF"`
- **THEN** it SHALL evaluate `sub-visibility` OR `secondary-sub-visibility`. If either is autonomously turned `ON` by mpv (for example: user pressing `j` to cycle secondary subs) while our custom OSD handles rendering, `master_tick` MUST forcefully turn BOTH native properties `false` again to prevent duplicate overlay logic.

#### Scenario: Subcontracting visibility to the Drum Window mode
- **WHEN** `FSM.DRUM_WINDOW` is `DOCKED`
- **THEN** `master_tick` SHALL bypass its continuous background visibility suppression loop completely, leaving `cmd_toggle_drum_window` directly in charge of its own visibility snap-shots.

### Requirement: Global Subtitle Quick Toggle (cmd_toggle_sub_vis)
The system SHALL ensure the "s" (global toggle) key updates the desired state uniformly, bypassing lower-level mode conflicts.

#### Scenario: User presses 's' to disable all subs
- **WHEN** user triggers `cmd_toggle_sub_vis()` when `FSM.native_sub_vis = true`
- **THEN** system SHALL set `FSM.native_sub_vis = false`, set native properties `sub-visibility` to false directly, and flush any `drum_osd` buffers.

### Requirement: OSD Styling Unification Bridge
The system SHALL respect the `FSM.DRUM` OFF state while still passing styling rules from OpenSpec specs through to `drum_osd` when Regular SRT mode requires explicit UI adjustments.

#### Scenario: User loads regular subtitles with OSD style rules
- **WHEN** `FSM.native_sub_vis` is true but custom `lls-srt_font_name` is set
- **THEN** the system SHALL hide native subtitles and execute `draw_drum()` with 0 context lines, serving as a styled pass-through instead of raw mpv OS-level rendering.

### Requirement: Global Media Context Gatekeeping (MEDIA_STATE)
The system SHALL evaluate the current tracks loaded into `FSM.MEDIA_STATE` and adjust dependent capabilities accordingly to prevent renderer crashes. 

#### Scenario: User loads an ASS tracking format
- **WHEN** `boot_subs()` evaluates tracks and finds an ASS codec (`FSM.MEDIA_STATE` includes `ASS`)
- **THEN** it SHALL force `FSM.DRUM = "OFF"` and `FSM.DRUM_WINDOW = "OFF"`, restoring native parameters, because ASS styling structures conflict heavily with internal OSD plain-text override parsers.

### Requirement: Autopause Coordination (AUTOPAUSE / SPACEBAR)
The system SHALL manage subtitle-boundary pausing autonomously based on FSM state flags without overlapping with user manual playback triggers.

#### Scenario: Autopause halts playback at subtitle boundaries
- **WHEN** `FSM.AUTOPAUSE == "ON"` and playback crosses the threshold of `FSM.last_paused_sub_end` 
- **THEN** it SHALL evaluate `FSM.SPACEBAR`. If `IDLE`, it pauses the player. If the user overrides via spacebar, the system yields until the next track boundary.

### Requirement: Tooltip Overlay Mutex (DW_TOOLTIP_MODE)
The system SHALL render analytical tooltips safely within the overarching Drum Window subsystem.

#### Scenario: Active Drum Window triggers tooltip
- **WHEN** `FSM.DRUM_WINDOW == "DOCKED"` and the user clicks/holds the left or middle mouse button (`DW_TOOLTIP_MODE ~= "OFF"`)
- **THEN** the system SHALL calculate the cursor position relative to the FSM coordinate grid, drawing `dw_tooltip_osd` with high priority.

### Requirement: Specialized Input States (SEARCH_MODE & COPY_MODE)
The system SHALL explicitly track modal interfaces that hijack default keyboard bindings to ensure that user input is correctly routed to transient UI components without triggering core media playback or navigation actions.

#### Scenario: Search Mode Hijack
- **WHEN** `FSM.SEARCH_MODE == true`
- **THEN** it SHALL instantiate a dedicated input grabber, routing all character keystrokes away from native bindings into the Search Query buffer (`FSM.SEARCH_QUERY`).
- **AND** the system SHALL render the `search_osd` overlay according to the visualization rules defined in the `search-system` spec.

### Requirement: European Character Search Support
The Search Mode input grabber SHALL support the entry of German umlauts and the eszett character, along with their uppercase variants, by including them in the forced key binding whitelist.

#### Scenario: User types German characters in search field
- **WHEN** FSM.SEARCH_MODE is true and the user presses 'ä', 'ö', 'ü', 'ß', 'Ä', 'Ö', 'Ü', or 'ẞ'
- **THEN** THE OSD SHALL capture these characters, append them to FSM.SEARCH_QUERY, and update the search results dynamically.

### Requirement: State-Driven Mode Management
The system SHALL determine its active operating mode (MEDIA_STATE) by dynamically parsing the current `track-list` of the media player.

#### Scenario: Detecting dual-language tracks
- **WHEN** the media player has both a primary and secondary subtitle track active
- **THEN** the system SHALL enter the `DUAL_ASS` or `DUAL_SRT` (or mixed) state as appropriate.

### Requirement: Consolidated Logic Core
The system SHALL centralize all core language learning features (Autopause, Context visualization, and Subtitle Copy) into a singular script architecture (`lls_core.lua`).

#### Scenario: Feature coordination
- **WHEN** multiple features are enabled simultaneously
- **THEN** their logic SHALL be executed sequentially within the centralized core to prevent race conditions.

### Requirement: Immersion Mode Transition FSM
The system SHALL ensure that transitions between Immersion Modes (`MOVIE`, `PHRASE`) do not trigger unintended seeking or playback behavior.
- **State Alignment**: When toggling to `PHRASE` mode, the system SHALL immediately synchronize `FSM.ACTIVE_IDX` with the current subtitle index based on `time-pos`.
- **Efficacy**: This synchronization MUST occur before the next tick of the master loop to prevent "Jerk Back" logic from detecting a phantom subtitle boundary.

#### Scenario: Syncing state on Phrase mode toggle
- **WHEN** the user toggles from `MOVIE` to `PHRASE` mode
- **THEN** the system SHALL calculate the current `active_idx` and store it in `FSM.ACTIVE_IDX` immediately.
- **AND** the subsequent tick loop SHALL NOT trigger a "Jerk Back" seek if the playback position is at a subtitle boundary.

### Requirement: Deterministic Focus Sentinel
The system SHALL use a persistent sentinel (`FSM.ACTIVE_IDX`) to maintain focus on the current subtitle fragment, preventing "Magnetic Snapping" caused by temporal padding.

#### Scenario: Subtitle Tail Protection
- **WHEN** playback continues past the technical duration of a subtitle
- **THEN** the sentinel SHALL remain locked until the playhead exits the `[Start-Pad, End+Pad]` window.

### Requirement: Behavioral Parameterization
The system SHALL externalize all state transition thresholds to allow for hardware-specific tuning and scientific reliability.

#### Scenario: Tuning the settle period
- **WHEN** the user modifies `Options.nav_cooldown`
- **THEN** the FSM SHALL apply the new duration to subsequent seek events without requiring a reload.

#### Scenario: Manual Navigation Settle Period
- **WHEN** a manual seek is detected
- **THEN** the system SHALL suspend automated FSM corrections for a duration defined by `Options.nav_cooldown` (Default: 0.5s).

#### Scenario: Overlap Precision
- **WHEN** calculating transition points
- **THEN** a tolerance defined by `Options.nav_tolerance` (Default: 0.05s) SHALL be applied to handle floating-point rounding errors.

