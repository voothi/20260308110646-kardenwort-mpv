## Purpose

The FSM Architecture manages unified state of the media player, coordinating subtitle visibility, operating modes, and feature boundaries to prevent race conditions and rendering conflicts.

## MODIFIED Requirements

### Requirement: Behavioral Parameterization
The system SHALL externalize all state transition thresholds to allow for hardware-specific tuning and scientific reliability.

#### Scenario: Tuning of settle period
- **WHEN** user modifies `Options.nav_cooldown`
- **THEN** FSM SHALL apply to new duration to subsequent seek events without requiring a reload.

#### Scenario: Manual Navigation Settle Period
- **WHEN** a manual seek is detected
- **THEN** system SHALL suspend automated FSM corrections for a duration defined by `Options.nav_cooldown` (Default: 0.2s).

#### Scenario: Overlap Precision
- **WHEN** calculating transition points
- **THEN** a tolerance defined by `Options.nav_tolerance` (Default: 0.05s) SHALL be applied to handle floating-point rounding errors.

## Requirements

### Requirement: Architecture and Subtitle Visibility Control Matrix
The system SHALL manage native and custom (OSD) subtitle visibilities via a unified Finite State Machine (FSM). `FSM.native_sub_vis` MUST act as overarching source of desired truth for standard playback, but actual on-screen rendering MUST obey mutual exclusion rules between `native`, `DRUM`, and `DRUM_WINDOW`.

#### Scenario: User toggles Drum Window from Regular Playback
- **WHEN** user engages Drum Window (`DRUM_WINDOW = 'DOCKED'`) while `FSM.DRUM = 'OFF'` and `FSM.native_sub_vis = true`
- **THEN** system SHALL snapshot visibility state, forcefully set native visibility properties to false, clear Drum regular OSD (if active via unified styling), and map Drum Window logic to screen exclusively.

#### Scenario: User toggles Drum Window OFF
- **WHEN** user disengages Drum Window
- **THEN** system SHALL restore layout tracking variables to `FSM.DW_SAVED_SUB_VIS` and gracefully reinstate native or OSD-based SRT subtitle rendering based on that state without user interference.

### Requirement: Mode Mutually Exclusive Execution (Master Tick)
The system SHALL funnel all periodic updates through `master_tick()`. Only one primary subtitle rendering engine (Native, Drum Mode OSD, Drum Window OSD) SHALL draw to screen at any given time.

#### Scenario: Master tick prevents native duplicate artefact
- **WHEN** 0.05s periodic timer fires `master_tick()` and `FSM.DRUM_WINDOW == "OFF"`
- **THEN** it SHALL evaluate `sub-visibility` OR `secondary-sub-visibility`. If either is autonomously turned `ON` by mpv (for example: user pressing `j` to cycle secondary subs) while our custom OSD handles rendering, `master_tick` MUST forcefully turn BOTH native properties `false` again to prevent duplicate overlay logic.

#### Scenario: Subcontracting visibility to Drum Window mode
- **WHEN** `FSM.DRUM_WINDOW` is `DOCKED`
- **THEN** `master_tick` SHALL bypass its continuous background visibility suppression loop completely, leaving `cmd_toggle_drum_window` directly in charge of its own visibility snapshots.

##### Requirement: Global Subtitle Quick Toggle (cmd_toggle_sub_vis)
The system SHALL ensure that "s" (global toggle) key updates desired state uniformly during standard playback. However, to prevent unintended background state mutations while interacting with Drum Window, toggle SHALL be suppressed when `FSM.DRUM_WINDOW` is active.

#### Scenario: User presses 's' to disable all subs
- **WHEN** user triggers `cmd_toggle_sub_vis()` when `FSM.native_sub_vis = true` and `FSM.DRUM_WINDOW == "OFF"`
- **THEN** system SHALL set `FSM.native_sub_vis = false`, set native properties `sub-visibility` to false directly, and flush any `drum_osd` buffers.

#### Scenario: User presses 's' while Drum Window is open
- **WHEN** user triggers `cmd_toggle_sub_vis()` while `FSM.DRUM_WINDOW ~= "OFF"`
- **THEN** system SHALL suppress the toggle action
- **AND** it SHALL provide visual feedback ("X") to user.

### Requirement: OSD Styling Unification Bridge
The system SHALL respect `FSM.DRUM` OFF state while still passing styling rules from OpenSpec specs through to `drum_osd` when Regular SRT mode requires explicit UI adjustments.

#### Scenario: User loads regular subtitles with OSD style rules
- **WHEN** `FSM.native_sub_vis` is true but custom `kardenwort-srt_font_name` is set
- **THEN** system SHALL hide native subtitles and execute `draw_drum()` with 0 context lines, serving as a styled pass-through instead of raw mpv OS-level rendering.

### Requirement: Global Media Context Gatekeeping (MEDIA_STATE)
The system SHALL evaluate current tracks loaded into `FSM.MEDIA_STATE` and adjust dependent capabilities accordingly to prevent renderer crashes and overlay conflicts.

#### Scenario: User loads an ASS tracking format
- **WHEN** track evaluation resolves an ASS-incompatible media context (`FSM.MEDIA_STATE` includes `ASS`)
- **THEN** system SHALL force `FSM.DRUM = "OFF"` and `FSM.DRUM_WINDOW = "OFF"` in the same transition cycle
- **AND** it SHALL restore native subtitle visibility and position properties from FSM-owned desired state variables.

### Requirement: Autopause Coordination (AUTOPAUSE / SPACEBAR)
The FSM SHALL coordinate autopause with a deterministic transit-inhibit lifecycle for manual navigation, including set, guarded execution, and clear phases.

#### Scenario: Transit inhibit lifecycle for cross-card navigation
- **WHEN** manual navigation or replay command determines a cross-card transition
- **THEN** FSM MUST set transit inhibition state before boundary evaluation
- **AND** master playback loop MUST honor inhibition gates for autopause and PHRASE jerk-back branches
- **AND** inhibition MUST clear only on deterministic completion criteria.

#### Scenario: Stale inhibit hygiene on unrelated manual jumps
- **WHEN** manual navigation actions occur outside of original rewind transit path
- **THEN** FSM MUST clear stale transit inhibition state before applying new navigation state
- **AND** subsequent boundary decisions MUST use current navigation context only.

### Requirement: Tooltip Overlay Mutex (DW_TOOLTIP_MODE)
The system SHALL render analytical tooltips safely within the overarching Drum Window subsystem.

#### Scenario: Active Drum Window triggers tooltip
- **WHEN** `FSM.DRUM_WINDOW == "DOCKED"` and user clicks/holds left or middle mouse button (`DW_TOOLTIP_MODE ~= "OFF"`)
- **THEN** system SHALL calculate cursor position relative to FSM coordinate grid, drawing `dw_tooltip_osd` with high priority.

### Requirement: Specialized Input States (SEARCH_MODE & COPY_MODE)
The system SHALL explicitly track modal interfaces that hijack default keyboard bindings to ensure that user input is correctly routed to transient UI components without triggering core media playback or navigation actions.

#### Scenario: Search Mode Hijack
- **WHEN** `FSM.SEARCH_MODE == true`
- **THEN** it SHALL instantiate a dedicated input grabber, routing all configured search-character bindings away from native bindings into Search Query buffer (`FSM.SEARCH_QUERY`)
- **AND** it SHALL render `search_osd` overlay according to the visualization rules defined in the `search-system` spec
- **AND** playback-altering hotkeys SHALL remain suppressed while modal grabber is active, except explicit search actions bound to modal navigation/commit.

#### Scenario: Search Enter commits selected result
- **WHEN** `FSM.SEARCH_MODE == true` and user presses configured Enter key
- **THEN** system SHALL execute search-result commit behavior (seek to selected result and close or exit search mode)
- **AND** it SHALL NOT invoke native non-search Enter behavior during that modal action.

### Requirement: European Character Search Support
The Search Mode input grabber SHALL support entry of German umlauts and eszett character, along with their uppercase variants, by including them in the forced key binding whitelist and by removing those same bindings when search mode exits.

#### Scenario: User types German characters in search field
- **WHEN** `FSM.SEARCH_MODE` is true and user presses `ä`, `ö`, `ü`, `ß`, `Ä`, `Ö`, `Ü`, or `ẞ`
- **THEN** OSD SHALL capture these characters, append them to `FSM.SEARCH_QUERY`, and update the search results dynamically.

#### Scenario: Search mode exits cleanly
- **WHEN** `FSM.SEARCH_MODE` transitions from true to false
- **THEN** every forced binding created for search character input, including the German whitelist characters, SHALL be removed in the same lifecycle path
- **AND** no search-character forced binding SHALL remain active after modal exit.
