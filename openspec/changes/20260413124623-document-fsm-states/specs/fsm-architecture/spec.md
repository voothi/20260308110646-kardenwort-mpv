## ADDED Requirements

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

#### Scenario: Master tick processes subtitle states
- **WHEN** the 0.05s periodic timer fires `master_tick()`
- **THEN** it SHALL evaluate `FSM.DRUM_WINDOW`. If `DOCKED`, execute `tick_dw()`. If `OFF` but `FSM.native_sub_vis` is true, execute `tick_drum()`. If `FSM.native_sub_vis` is true but native `sub-visibility` is active while OSD rendering is desired (e.g. `DRUM = 'ON'` or `srt_font_size` config detected), hide mpv's native strings properties explicitly.

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
