# Specifications: Immersion Engine Hardening

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
