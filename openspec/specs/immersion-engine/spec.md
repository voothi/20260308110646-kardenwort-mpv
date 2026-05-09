# Specifications: Immersion Engine

## ADDED Requirements

### Requirement: Deterministic Focus Sentinel
The immersion engine MUST use a persistent sentinel (`FSM.ACTIVE_IDX`) to maintain subtitle focus, preventing proximity-based snapping in padded regions.

#### Scenario: Normal Playback through Padded End
- **WHEN** Playback reaches the technical end of subtitle `i`.
- **THEN** Focus MUST remain on `i` until `End + audio_padding_end` is reached, ensuring the audio tail is preserved.

#### Scenario: Transition into Overlap (Phrases Mode)
- **WHEN** Focus on subtitle `i` expires and subtitle `i+1`'s padded start has already begun.
- **THEN** The engine MUST immediately transition to `i+1` and perform a "Jerk-Back" seek to its padded start (`Start - audio_padding_start`).

### Requirement: Mode-Aware Boundary Handover
The calculation of subtitle "Effective Boundaries" MUST be sensitive to the `IMMERSION_MODE` state.

#### Scenario: Movie Mode Handover
- **WHEN** `IMMERSION_MODE == "MOVIE"`.
- **THEN** The effective end of subtitle `i` MUST be set to the padded start of subtitle `i+1` (`Next_Start - audio_padding_start`), creating a gapless cinematic transition.

### Requirement: Filtered Secondary Subtitle Cycling
The `Shift+c` command MUST filter the `track-list` to provide a clean cycling experience between supported external tracks.

#### Scenario: Cycling with Internal Tracks Present
- **WHEN** The video contains built-in PGS/HD subtitles and external SRT/ASS files.
- **THEN** `Shift+c` MUST skip the internal tracks and cycle only between `OFF` and the `external` tracks.
- **THEN** The OSD MUST indicate the number of hidden unsupported tracks (e.g., `[2 built-in hidden]`).

### Requirement: Scientific Behavioral Parameters
All temporal thresholds driving the FSM MUST be configurable via `script-opts`.

#### Scenario: Manual Navigation Settle Period
- **WHEN** A manual seek (`a`, `d`, `Enter`) is performed.
- **THEN** Automated "Jerk-Back" logic MUST be suspended for `nav_cooldown` (Default: 0.5s) to allow state synchronization.

#### Scenario: Overlap Precision
- **WHEN** Detecting overlaps or gaps between subtitles.
- **THEN** A tolerance of `nav_tolerance` (Default: 0.05s) MUST be applied to prevent floating-point errors from causing "stuck" states.

### Requirement: Navigation-Aware Boundary Suppression
The immersion engine MUST suppress all autopause triggers and boundary-enforced stops during intentional subtitle navigation.

#### Scenario: Subtitle Rewind (Shift+a) in Phrases Mode
- **WHEN** `FSM.AUTOPAUSE == "ON"`.
- **AND** The user performs a subtitle jump (`Shift+a` or `Shift+d`).
- **THEN** All boundary-based pause triggers MUST be suspended for the duration of the jump and a subsequent "settle" period.
- **AND** The system MUST NOT treat the entry into the target subtitle's padded boundary as a "Natural Progression" pause event.

#### Scenario: Transient Movie Mode Guard
- **WHEN** A manual subtitle jump is initiated.
- **THEN** The engine MUST internally treat the transition as a `MOVIE` mode handover (gapless) to prevent the "jerking" effect of padded boundaries.
- **AND** Normal `PHRASE` mode behavior MUST be restored once the playhead reaches the target subtitle's effective start.

## HARDENED Requirements

### Requirement: One-step Natural Progression in get_center_index
The `get_center_index` function MUST apply a **Natural Progression** check after the sticky sentinel check and **before** falling through to the binary search. When `FSM.ACTIVE_IDX` is set and its effective boundary has expired, the engine MUST first test if the consecutive next sub (`ACTIVE_IDX+1`) has a padded zone that contains `time_pos`. If it does, the function MUST return `ACTIVE_IDX+1` immediately, without consulting the binary search result.

This requirement closes the **Large-Padding Sub-Skip** regression: with `audio_padding_start ≥ 500ms`, multiple subtitles' padded zones can overlap `time_pos` simultaneously. The previous Overlap Priority (`best+1` from binary search) was only correct for the default 200ms padding, where at most one overlap exists. With large padding, `best+1` skips over intermediate subtitles entirely.

The phrase *"transition to `i+1`"* in all immersion engine scenarios MUST be interpreted as **the consecutive next subtitle** (index `ACTIVE_IDX+1`), never a further jump derived from binary search promotion.

#### Scenario: Large-Padding Overlap (PHRASE Mode)
- **WHEN** `audio_padding_start` ≥ 500ms causes three or more subtitles' padded zones to overlap `time_pos` simultaneously.
- **AND** `FSM.ACTIVE_IDX` is set to sub `i` and its effective end has just been exceeded.
- **THEN** `get_center_index` MUST return `i+1` (the consecutive next sub).
- **AND** it MUST NOT return `i+2` or any further index derived from binary search + Overlap Priority promotion.

#### Scenario: Natural Progression MOVIE mode fallthrough
- **WHEN** Natural Progression fires in MOVIE mode and `time_pos > e_next` (beyond sub `i+1`'s effective end).
- **THEN** the Natural Progression check MUST NOT fire (`time_pos <= e_next` guard prevents it).
- **AND** the binary search path MUST handle the MOVIE gapless handover as before.

- **WHEN** `FSM.ACTIVE_IDX == -1` (cold entry, scrub, or file-open with no prior focus).
- **THEN** Natural Progression MUST NOT fire.
- **AND** the binary search + Overlap Priority path handles initial focus acquisition as before.

### Requirement: Immersion Engine - Adaptive Replay and Looping
The immersion engine must correctly handle subtitle replay and looping as per archives 20260504174809 and 20260504021904.

#### Scenario: Subtitle Replay in Autopause ON
- **WHEN** the `s` key is pressed during playback of a subtitle.
- **THEN** the subtitle should play to its end and then restart from its beginning for the configured number of repetitions.

#### Scenario: Subtitle Looping in Autopause OFF
- **WHEN** the `s` key is pressed while Autopause is OFF.
- **THEN** the current subtitle should loop indefinitely until interrupted.

### Requirement: Drum Mode - Navigation and Cursor Sync
Drum mode must maintain cursor synchronization and allow reliable navigation as per archives 20260504033538 and 20260502104026.

#### Scenario: Cursor Sync on Navigation
- **WHEN** navigating between subtitles in Drum Mode.
- **THEN** the yellow pointer and selection state must remain synchronized between the primary and secondary tracks.
