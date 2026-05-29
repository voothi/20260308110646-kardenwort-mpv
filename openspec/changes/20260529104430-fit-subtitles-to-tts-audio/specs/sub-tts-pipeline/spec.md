## MODIFIED Requirements

### Requirement: Timed audio assembly
The system SHALL assemble the per-cue WAV files into a single audio track where each cue's audio is positioned at its (possibly shifted) start time.

Silent gaps SHALL be preserved between cues when the synthesized audio fits within the original subtitle timing.

If a synthesized cue's audio duration exceeds the available window (from its start time to the next cue's start time), the system SHALL NOT shift subsequent cues later in the default subtitle-locked mode. The overflowing cue MAY overlap the following cue, and the system SHALL report a timing warning that includes the number of overflowing cues and the largest overflow duration.

The system SHALL expose timing placement as a testable plan before FFmpeg assembly so overflow behavior can be validated without running Piper or FFmpeg.

Before final assembly, the system SHALL run a Subtitle Edit-style speed fitting stage when `fit_to_subtitle=true`:
1. Trim leading/trailing silence from each cue WAV.
2. Optionally compress internal silence when configured.
3. Allow a configurable portion of the following subtitle gap as extra target duration.
4. Speed up only cue WAVs that still exceed the target duration.
5. Preserve pitch using FFmpeg `rubberband` when enabled and available, otherwise use `atempo`.

The system SHALL cap automatic speed-up using `max_speed_factor` and SHALL report remaining overflow when the cap prevents a perfect fit.

When the opt-in `fit_subtitle_to_audio` mode is enabled, the system SHALL run a subtitle-shift planner **after** the speed-fitting stage and **before** audio assembly. The planner SHALL:
1. Iterate over cues in original order, maintaining an accumulated drift value initialized to zero.
2. Apply the current drift to each cue's start_ms and end_ms.
3. Compute the cue's audio_end as shifted_start_ms + synthesized_wav_duration_ms.
4. If audio_end exceeds the next cue's shifted start_ms, increase drift by the difference so the next cue's shifted start_ms equals at least audio_end.
5. Never decrease drift (cues are only ever moved later, never earlier).
6. Produce a shift_plan list indexed by cue position, where each entry records the total drift applied at that cue.

When the shift planner runs, the overflow warning produced by the assembly stage SHALL be suppressed for cues whose post-shift overflow is zero (any residual overflow from WAV-duration rounding still triggers a warning).

The system SHALL log a single info line summarizing the planner's effect: number of shifted cues and total accumulated drift in seconds.

#### Scenario: Two cues with gap
- **WHEN** cue 1 starts at 00:00:01.000 and cue 2 starts at 00:00:05.000
- **AND** cue 1's synthesized audio is 2 seconds long
- **THEN** the assembled audio SHALL have cue 1's audio at t=1s, then 2 seconds of silence, then cue 2's audio at t=5s

#### Scenario: Overlapping cue audio
- **WHEN** cue 1 starts at 00:00:01.000, cue 2 starts at 00:00:02.000
- **AND** cue 1's synthesized audio is 3 seconds long
- **THEN** cue 2's audio SHALL still start at t=2s in subtitle-locked mode
- **AND** the system SHALL report that cue 1 overflows the next cue by 2 seconds

#### Scenario: Timing plan can be tested without media processing
- **WHEN** cue WAV durations are known
- **THEN** the system SHALL produce a timing plan with cue start, audio end, next cue start, and overflow fields

#### Scenario: Long cue is sped up to fit subtitle window
- **WHEN** a cue's generated WAV is 9000ms long
- **AND** the subtitle window plus allowed following gap is 6000ms
- **THEN** the system SHALL apply a 1.5x speed factor before assembly

#### Scenario: Speed factor is capped
- **WHEN** a cue would require 3.0x speed to fit
- **AND** `max_speed_factor` is `2.0`
- **THEN** the system SHALL apply no more than 2.0x speed
- **AND** the remaining overflow SHALL be reported

#### Scenario: Shift planner moves overflowing cue's successor
- **WHEN** `fit_subtitle_to_audio` is true
- **AND** cue 1 starts at 1000ms with a post-speed-fit WAV of 3000ms duration
- **AND** cue 2 starts at 2000ms in the source SRT
- **THEN** the planner SHALL shift cue 2's start_ms to 4000ms
- **AND** the shift_plan entry for cue 2 SHALL record a drift of 2000ms

#### Scenario: Shift planner accumulates drift across cues
- **WHEN** `fit_subtitle_to_audio` is true
- **AND** cue 1 (start 0ms, WAV 1500ms) and cue 2 (start 1000ms, WAV 1500ms) and cue 3 (start 2000ms) form the input
- **THEN** cue 2 SHALL shift to 1500ms (drift 500ms)
- **AND** cue 3 SHALL shift to 3000ms (drift 1000ms accumulated)

#### Scenario: Shift planner never pulls cues earlier
- **WHEN** `fit_subtitle_to_audio` is true
- **AND** a cue's WAV is shorter than its subtitle window (no overflow)
- **THEN** the next cue's start_ms SHALL remain unchanged (drift does not decrease)

#### Scenario: Overflow warning suppressed when planner absorbs overflow
- **WHEN** `fit_subtitle_to_audio` is true
- **AND** the planner shifts every overflowing cue's successor cleanly
- **THEN** the assembly stage SHALL NOT print the "N synthesized cue(s) exceed the next subtitle start" warning for those cues

#### Scenario: Shift planner is a no-op when mode is off
- **WHEN** `fit_subtitle_to_audio` is false (default)
- **THEN** no shift_plan SHALL be produced
- **AND** all cues SHALL retain their original SRT start_ms and end_ms
- **AND** the existing overflow warning behavior SHALL be unchanged

---

### Requirement: Configuration file
The system SHALL read its configuration from `scripts/_tools/sub-tts/config.ini` with the following sections:

- `[paths]`: `piper_tts_root` (path to piper-tts project), `ffmpeg_executable` (path to ffmpeg.exe), `zid_script` (path to zid.py).
- `[tts_settings]`: `default_lang` (fallback language), `duplicate_mode` (zid-dir | skip | overwrite).
- `[tts_settings]`: `fit_to_subtitle`, `vad_silence_compression`, `vad_max_silence_seconds`, `high_quality_time_stretch`, `max_extra_gap_ms`, `max_speed_factor`, `fit_subtitle_to_audio`.
- `[lang_aliases]`: Optional postfix-to-language overrides (e.g., `ger = de`, `rus = ru`, `eng = en`).

The `fit_subtitle_to_audio` key SHALL be a boolean that defaults to `false` when absent. When `true`, it enables the subtitle-shift planner described in the **Timed audio assembly** requirement.

#### Scenario: Config file missing
- **WHEN** `config.ini` does not exist
- **THEN** the system SHALL print an error message referencing `config.ini.template` and exit with code 1

#### Scenario: Custom alias mapping
- **WHEN** `config.ini` contains `[lang_aliases]` with `ger = de`
- **AND** the input file is `video.ger.srt`
- **THEN** the system SHALL resolve language `de`

#### Scenario: fit_subtitle_to_audio defaults to false
- **WHEN** `config.ini` does not contain a `fit_subtitle_to_audio` key
- **THEN** the system SHALL treat the value as `false`
- **AND** the output SHALL be byte-equivalent to the prior pipeline's output for the same input

#### Scenario: fit_subtitle_to_audio enabled via config
- **WHEN** `config.ini` contains `fit_subtitle_to_audio = true` under `[tts_settings]`
- **AND** no CLI override is passed
- **THEN** the system SHALL run the subtitle-shift planner during processing

---

### Requirement: CLI interface
The system SHALL support direct CLI invocation with the following arguments:
- Positional: one or more SRT file paths.
- `--lang`: Override language detection (bypass postfix detection).
- `--output-dir`: Override output directory.
- `--ffmpeg-path`: Override FFmpeg path from config.
- `--keep-lang-postfix` / `--no-keep-lang-postfix`: Override `keep_lang_postfix` config (`None` falls back to config).
- `--fit-subtitle-to-audio` / `--no-fit-subtitle-to-audio`: Override `fit_subtitle_to_audio` config (`None` falls back to config).

CLI overrides SHALL take precedence over config values when explicitly passed.

#### Scenario: CLI with explicit language
- **WHEN** invoked as `python sub_tts.py --lang de video.srt`
- **THEN** the system SHALL use language `de` regardless of the filename postfix

#### Scenario: CLI with multiple files
- **WHEN** invoked as `python sub_tts.py video.de.srt lesson.ru.srt`
- **THEN** the system SHALL process both files, detecting language per-file from postfix

#### Scenario: CLI fit-subtitle-to-audio enables planner
- **WHEN** invoked as `python sub_tts.py --fit-subtitle-to-audio video.de.srt`
- **AND** `config.ini` has `fit_subtitle_to_audio = false`
- **THEN** the system SHALL run the subtitle-shift planner for this invocation

#### Scenario: CLI no-fit-subtitle-to-audio overrides enabled config
- **WHEN** invoked as `python sub_tts.py --no-fit-subtitle-to-audio video.de.srt`
- **AND** `config.ini` has `fit_subtitle_to_audio = true`
- **THEN** the system SHALL NOT run the subtitle-shift planner for this invocation

---

### Requirement: Windows SendTo integration
The system SHALL provide an `install.py` script that creates a Windows "Send to" shortcut named "Kardenwort Sub TTS".

The shortcut SHALL accept one or more `.srt` files dropped via the Windows Explorer "Send to" context menu and invoke `sub_tts.py` with those files as arguments.

The shortcut SHALL use `python.exe` and keep a visible console window open after completion so progress, timing warnings, and error diagnostics can be read.

When multiple SRT files are processed in a single invocation **and** the subtitle-shift planner is active, the system SHALL derive the shift plan from the first file (the canonical/source file in order of CLI arguments) and SHALL replay that shift plan onto every subsequent file by cue index position. The planner SHALL NOT run independently for the subsequent files. When a subsequent file has fewer cues than the canonical plan, only the overlapping prefix SHALL be shifted; when it has more cues, the trailing cues SHALL retain their original timing. In either mismatch case, the system SHALL log a single warning naming the file and the cue-count mismatch.

#### Scenario: SendTo installation
- **WHEN** the user runs `python install.py`
- **THEN** a shortcut named "Kardenwort Sub TTS.lnk" SHALL be created in the user's SendTo directory
- **AND** the shortcut SHALL target `python.exe` with `sub_tts.py --sendto --pause` as arguments

#### Scenario: Multiple file SendTo
- **WHEN** the user selects 3 SRT files and uses "Send to" → "Kardenwort Sub TTS"
- **THEN** the system SHALL process all 3 files sequentially, generating one MP4 per SRT file

#### Scenario: Multi-file lockstep shift propagation
- **WHEN** `fit_subtitle_to_audio` is true
- **AND** the user processes `lesson.en.srt` and `lesson.ru.srt` together in one invocation, in that order
- **AND** processing `lesson.en.srt` produces a shift plan moving cue 5 by 800ms
- **THEN** when processing `lesson.ru.srt`, cue 5's start_ms SHALL also be shifted by 800ms (drift inherited from cue 4 + any new drift suppressed)
- **AND** the system SHALL log "Applying canonical shift plan from lesson.en.srt"

#### Scenario: Multi-file cue-count mismatch
- **WHEN** `fit_subtitle_to_audio` is true
- **AND** the canonical first file has 100 cues
- **AND** a subsequent file has 95 cues
- **THEN** the shift plan SHALL apply to the first 95 cues of the second file
- **AND** the system SHALL log a single warning naming the mismatched file and counts (100 vs 95)
