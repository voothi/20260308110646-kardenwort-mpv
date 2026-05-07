## ADDED Requirements

### Requirement: Natural Progression Verification
The system SHALL transition from subtitle index `i` to `i+1` as soon as the playhead enters the padded start region of subtitle `i+1`, even if subtitle `i`'s padded end has not yet been reached.

#### Scenario: Smooth transition in overlap zone
- **WHEN** playhead is at `time_pos` such that `time_pos >= subs[i+1].start_time - pad_start` AND `time_pos <= subs[i].end_time + pad_end`
- **THEN** `FSM.ACTIVE_IDX` MUST be `i+1`

### Requirement: Seek Repeatability Verification
The "lls-seek_time_forward" and "lls-seek_time_backward" keybindings MUST be configured as repeatable in the mpv input layer.

#### Scenario: Verification of repeatable flag
- **WHEN** inspecting mpv `input-bindings`
- **THEN** the bindings for `lls-seek_time_forward` and `lls-seek_time_backward` SHALL have `repeatable: true`

### Requirement: Movie Mode Boundary Verification
In `MOVIE` mode, the autopause trigger MUST NOT fire before the subtitle's SRT `end_time`, ensuring the full subtitle duration is audible even if the next subtitle's padded start follows closely.

#### Scenario: Autopause compliance at small gaps
- **WHEN** `FSM.IMMERSION_MODE == "MOVIE"` and `FSM.AUTOPAUSE == "ON"`
- **AND** a small gap exists between subtitle `i` and `i+1`
- **THEN** the player SHALL NOT pause until `time_pos >= subs[i].end_time`

### Requirement: FSM Architecture Gap Verification
The FSM SHALL maintain correct state for subtitle visibility and secondary track positioning regardless of active OSD modes (e.g., Drum Window).

#### Scenario: Subtitle visibility toggle in Drum Window
- **WHEN** `FSM.DRUM_WINDOW` is active and `cmd_toggle_sub_vis` is triggered
- **THEN** `FSM.native_sub_vis` SHALL toggle correctly
- **AND** the Drum Window OSD SHALL continue to render without interruption

#### Scenario: Secondary subtitle position synchronization
- **WHEN** `cmd_adjust_sec_sub_pos` is called
- **THEN** `FSM.native_sec_sub_pos` SHALL be synchronized with the new `secondary-sub-pos` value
