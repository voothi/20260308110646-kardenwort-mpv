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
The system SHALL ensure the "s" (global toggle) key updates the desired state uniformly, bypassing lower-level mode conflicts. `FSM.native_sub_vis` and `FSM.native_sec_sub_vis` MUST be toggled regardless of whether `FSM.DRUM_WINDOW` is active. When `FSM.DRUM_WINDOW` is active, the Drum Window OSD surface is independent of `FSM.native_sub_vis` and SHALL continue rendering; the toggle updates the FSM desired-state so that the correct visibility is applied when the Drum Window is later closed.

#### Scenario: User presses 's' to disable all subs
- **WHEN** user triggers `cmd_toggle_sub_vis()` when `FSM.native_sub_vis = true`
- **THEN** system SHALL set `FSM.native_sub_vis = false`, set native properties `sub-visibility` to false directly, and flush any `drum_osd` buffers.

#### Scenario: User presses 's' while Drum Window is open
- **WHEN** user triggers `cmd_toggle_sub_vis()` while `FSM.DRUM_WINDOW == "DOCKED"`
- **THEN** system SHALL toggle `FSM.native_sub_vis` and `FSM.native_sec_sub_vis` as normal
- **AND** the Drum Window OSD surface SHALL continue rendering without interruption
- **AND** when the Drum Window is subsequently closed, the restored visibility SHALL reflect the toggled FSM desired-state.

### Requirement: OSD Styling Unification Bridge
The system SHALL respect the `FSM.DRUM` OFF state while still passing styling rules from OpenSpec specs through to `drum_osd` when Regular SRT mode requires explicit UI adjustments.

#### Scenario: User loads regular subtitles with OSD style rules
- **WHEN** `FSM.native_sub_vis` is true but custom `lls-srt_font_name` is set
- **THEN** the system SHALL hide native subtitles and execute `draw_drum()` with 0 context lines, serving as a styled pass-through instead of raw mpv OS-level rendering.

### Requirement: Global Media Context Gatekeeping (MEDIA_STATE)
The system SHALL evaluate the current tracks loaded into `FSM.MEDIA_STATE` and adjust dependent capabilities accordingly to prevent renderer crashes and overlay conflicts.

#### Scenario: User loads an ASS tracking format
- **WHEN** track evaluation resolves an ASS-incompatible media context (`FSM.MEDIA_STATE` includes `ASS`)
- **THEN** the system SHALL force `FSM.DRUM = "OFF"` and `FSM.DRUM_WINDOW = "OFF"` in the same transition cycle
- **AND** it SHALL restore native subtitle visibility and position properties from FSM-owned desired state variables.

### Requirement: Autopause Coordination (AUTOPAUSE / SPACEBAR)
The system SHALL manage subtitle-boundary pausing autonomously based on FSM state flags. To ensure the audible tail is fully preserved, the autopause trigger MUST evaluate the end-of-subtitle threshold against the index resolved by the Deterministic Focus Sentinel.

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
- **THEN** it SHALL instantiate a dedicated input grabber, routing all configured search-character bindings away from native bindings into the Search Query buffer (`FSM.SEARCH_QUERY`)
- **AND** it SHALL render the `search_osd` overlay according to the visualization rules defined in the `search-system` spec
- **AND** playback-altering hotkeys SHALL remain suppressed while the modal grabber is active, except explicit search actions bound to modal navigation/commit.

#### Scenario: Search Enter commits selected result
- **WHEN** `FSM.SEARCH_MODE == true` and the user presses the configured Enter key
- **THEN** the system SHALL execute search-result commit behavior (seek to selected result and close or exit search mode)
- **AND** it SHALL NOT invoke native non-search Enter behavior during that modal action.

### Requirement: European Character Search Support
The Search Mode input grabber SHALL support the entry of German umlauts and the eszett character, along with their uppercase variants, by including them in the forced key binding whitelist and by removing those same bindings when search mode exits.

#### Scenario: User types German characters in search field
- **WHEN** `FSM.SEARCH_MODE` is true and the user presses `ä`, `ö`, `ü`, `ß`, `Ä`, `Ö`, `Ü`, or `ẞ`
- **THEN** the OSD SHALL capture these characters, append them to `FSM.SEARCH_QUERY`, and update the search results dynamically.

#### Scenario: Search mode exits cleanly
- **WHEN** `FSM.SEARCH_MODE` transitions from true to false
- **THEN** every forced binding created for search character input, including the German whitelist characters, SHALL be removed in the same lifecycle path
- **AND** no search-character forced binding SHALL remain active after modal exit.

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

### Requirement: Deterministic Startup State
The system SHALL initialize the `IMMERSION_MODE` state at boot based on the user-defined `immersion_mode_default` parameter to ensure a consistent startup experience.
- **Boot Sequence**: The FSM SHALL evaluate the configuration after `read_options` but before the first media-ready event.
- **Fallback**: If the configuration is missing or invalid, the system SHALL default to `PHRASE` mode.

#### Scenario: Startup mode initialization from configuration
- **WHEN** the script initializes and evaluates `immersion_mode_default`
- **THEN** it SHALL set `FSM.IMMERSION_MODE` to the configured valid value (`PHRASE` or `MOVIE`)
- **AND** it SHALL fall back to `PHRASE` when the value is missing or invalid.

### Requirement: Deterministic Focus Sentinel
The system SHALL use a persistent sentinel (`FSM.ACTIVE_IDX`) to maintain focus on the current subtitle fragment, preventing "Magnetic Snapping" caused by temporal padding. The sentinel MUST only be applied when resolving indices against the primary subtitle track. When `get_center_index` is called with the secondary subtitle array, the sentinel SHALL NOT be applied (secondary track uses binary search resolution without a cross-track index assumption). To protect Jerk-Back logic in Phrase Mode and prevent audio clipping, the index resolution function (`get_center_index`) MUST follow a strict evaluation hierarchy:
1. **Sentinel (Early Return)**: If resolving the primary track and the playhead is within the `[Start-Pad, End+Pad]` window of the current `FSM.ACTIVE_IDX`, return the current index immediately.
2. **Natural Progression**: If resolving the primary track and `FSM.ACTIVE_IDX` is set and the consecutive next sub (`ACTIVE_IDX+1`) has a padded zone that contains `time_pos`, return `ACTIVE_IDX+1` immediately. This enforces one-step transition (`i → i+1`) and prevents intermediate subs from being skipped when large `audio_padding_start` values cause multiple subs' padded zones to overlap simultaneously.
3. **Standard Resolution**: Perform a binary search for the first subtitle starting at or before `time_pos`.
4. **Overlap Priority**: If a subsequent subtitle's padded start has begun, handover control only if the Sentinel has no claim. (Cold-entry only — Natural Progression supersedes this during sequential playback.)

#### Scenario: Subtitle Tail Protection
- **WHEN** playback continues past the technical duration of a subtitle
- **THEN** the sentinel SHALL remain locked until the playhead exits the `[Start-Pad, End+Pad]` window.

#### Scenario: Secondary track resolution uses no cross-track sentinel
- **WHEN** `get_center_index` is called with the secondary subtitle array
- **THEN** it SHALL NOT use `FSM.ACTIVE_IDX` (a primary-track index) as a sentinel for secondary array lookup
- **AND** resolution SHALL fall through directly to standard binary search.

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

### Requirement: Esc Stage Contract Consistency
The system SHALL keep a deterministic staged-Esc contract for Drum Window selection state and ensure documentation and runtime behavior remain aligned.

#### Scenario: Esc peel-back order remains deterministic
- **WHEN** the user triggers `cmd_dw_esc` with active selection state
- **THEN** stage resolution SHALL peel back in order: Pink Set -> Yellow Range -> Yellow Pointer
- **AND** each stage SHALL be independently idempotent so repeated Esc presses do not reintroduce cleared state.

#### Scenario: No implicit window close in selection-stage Esc path
- **WHEN** no staged selection state remains
- **THEN** `cmd_dw_esc` SHALL not implicitly mutate unrelated window lifecycle state in the same command path unless explicitly specified by a separate requirement.

### Requirement: DOCKED Positioning Neutrality by Layout Ownership
In `DOCKED` mode, deterministic visual alignment SHALL be achieved by the dedicated DW layout/render pipeline owning final positioning decisions.

#### Scenario: DOCKED rendering uses deterministic layout ownership
- **WHEN** `FSM.DRUM_WINDOW == "DOCKED"`
- **THEN** the visual stream SHALL be rendered through the DW layout pipeline with deterministic anchors and wrapping rules
- **AND** positioning neutrality MAY be satisfied either by stripping conflicting positioning tags or by rendering paths that do not depend on source `\pos` / `\an` tags.

### Requirement: Secondary Position Bounds via Configuration
Secondary subtitle positioning transitions SHALL respect configured FSM bounds rather than hardcoded constants. `FSM.native_sec_sub_pos` SHALL be kept synchronized with the actual mpv `secondary-sub-pos` property at all times, including after delta-based position adjustments, so that direction-aware toggle operations always operate from correct state.

#### Scenario: Cycling secondary subtitle position
- **WHEN** `cycle-secondary-pos` is triggered
- **THEN** the system SHALL toggle `secondary-sub-pos` between `Options.sec_pos_top` and `Options.sec_pos_bottom`
- **AND** overlap avoidance SHALL be achieved by validated configuration defaults (for example `sec_pos_bottom = 90` relative to primary `95`), not by implicit runtime clamping.

#### Scenario: Delta position adjustment syncs FSM state
- **WHEN** `cmd_adjust_sec_sub_pos` is called with a delta value
- **THEN** the system SHALL compute the new position, apply it to the mpv property, and write the same value back to `FSM.native_sec_sub_pos`
- **AND** a subsequent call to `cmd_cycle_sec_pos` SHALL use the synchronized `FSM.native_sec_sub_pos` to determine correct toggle direction.

### Requirement: Drum Tooltip Overlay Ownership Gate
The FSM SHALL permit tooltip overlay rendering in Drum Mode only when Drum Mode owns the primary OSD surface and Drum Window is inactive.

#### Scenario: Drum-owned tooltip render eligibility
- **WHEN** `FSM.DRUM == "ON"` and `FSM.DRUM_WINDOW == "OFF"`
- **THEN** Drum Mode tooltip rendering SHALL be eligible
- **AND** eligibility SHALL be revoked immediately when either condition becomes false.

### Requirement: Transition-Edge Tooltip Invalidation
The FSM SHALL clear tooltip visual state and invalidate tooltip hit-zones on every transition edge that changes tooltip ownership between Drum Mode and Drum Window.

#### Scenario: Switching from Drum Mode to Drum Window
- **WHEN** `FSM.DRUM_WINDOW` transitions from `"OFF"` to `"DOCKED"` while Drum tooltip state is active
- **THEN** Drum tooltip overlay buffers and Drum tooltip hit-zones SHALL be cleared before DW tooltip ownership is applied.

