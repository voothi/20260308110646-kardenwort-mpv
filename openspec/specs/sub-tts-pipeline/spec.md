# sub-tts-pipeline Specification

## Purpose
TBD - created by archiving change 20260526184741-sub-tts-pipeline. Update Purpose after archive.
## Requirements
### Requirement: Language auto-detection from filename postfix
The system SHALL detect the target TTS language from the subtitle filename's postfix segment before the `.srt` extension. The postfix segment is the text between the last two dots in the filename (e.g., in `video.de.srt`, the postfix is `de`).

Supported postfix mappings SHALL include at minimum: `de`, `ru`, `en`, `uk`, `es`, `fr`, `it`, `eng`, `ger`, `rus`.

The system SHALL normalize extended postfixes to their short form (e.g., `eng` → `en`, `ger` → `de`, `rus` → `ru`) before resolving the Piper TTS model.

When no language postfix is detected (e.g., `video.srt`), the system SHALL use the configured default language from `config.ini`.

#### Scenario: German subtitle file
- **WHEN** the input file is `video.de.srt`
- **THEN** the system SHALL resolve language `de` and use the Piper TTS `voice_de` model

#### Scenario: Russian subtitle with extended postfix
- **WHEN** the input file is `lesson.rus.srt`
- **THEN** the system SHALL normalize `rus` to `ru` and use the Piper TTS `voice_ru` model

#### Scenario: No language postfix
- **WHEN** the input file is `video.srt`
- **THEN** the system SHALL use the default language from `config.ini` (e.g., `en`)

#### Scenario: Unsupported language postfix
- **WHEN** the input file is `video.ja.srt` and no `voice_ja` section exists in Piper's config
- **THEN** the system SHALL report an error naming the unsupported language and exit without processing

---

### Requirement: SRT parsing and per-cue synthesis
The system SHALL parse SRT subtitle files, extracting each cue's index, start time, end time, and text content.

For each cue, the system SHALL invoke Piper TTS to synthesize a WAV audio file containing the spoken text of that cue.

HTML tags and SRT formatting tags (e.g., `<i>`, `<b>`, `{\an8}`) SHALL be stripped from the text before synthesis.

#### Scenario: Standard SRT with 3 cues
- **WHEN** the input SRT contains 3 subtitle entries with text
- **THEN** the system SHALL generate 3 individual WAV files, one per cue

#### Scenario: Cue with HTML tags
- **WHEN** a cue contains `<i>Hello</i> world`
- **THEN** the text passed to Piper TTS SHALL be `Hello world`

#### Scenario: Empty cue text
- **WHEN** a cue contains no text (only whitespace or empty after tag stripping)
- **THEN** the system SHALL skip that cue and not invoke Piper TTS for it

---

### Requirement: Timed audio assembly
The system SHALL assemble the per-cue WAV files into a single audio track where each cue's audio is positioned at its SRT start time.

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

---

### Requirement: MP4 output generation
The system SHALL produce an MP4 file containing:
1. A black video canvas track (matching Convert Media's encoding parameters).
2. The assembled synthesized audio as the audio track.

The output file SHALL be named `<basename-without-language-postfix>.mp4` and placed in the same directory as the source SRT file (e.g., `video.de.srt` → `video.mp4`).

When the output file already exists, the system SHALL use ZID-based duplicate handling (create a subdirectory named with the current ZID timestamp and place the output there).

#### Scenario: Successful MP4 generation
- **WHEN** processing `video.de.srt` completes successfully
- **THEN** the output file `video.mp4` SHALL exist in the same directory as the SRT file
- **AND** the MP4 SHALL contain a black video track and the synthesized audio track

#### Scenario: Duplicate output handling
- **WHEN** `video.mp4` already exists in the output directory
- **THEN** the system SHALL create a ZID-named subdirectory (e.g., `20260526184741/`) and place `video.mp4` inside it

---

### Requirement: Temporary file cleanup
The system SHALL create all intermediate WAV files in a temporary directory within the output folder.

After successful MP4 generation, the system SHALL delete all temporary WAV files and the temporary directory.

On failure, the system SHALL preserve temporary files for debugging and report their location.

#### Scenario: Successful cleanup
- **WHEN** MP4 generation succeeds
- **THEN** no temporary WAV files SHALL remain on disk

#### Scenario: Failed cleanup preservation
- **WHEN** FFmpeg fails during MP4 muxing
- **THEN** the temporary WAV files SHALL be preserved
- **AND** the error message SHALL include the path to the temporary directory

---

### Requirement: Progress reporting
The system SHALL report processing progress to stdout, including:
- The detected language and selected voice model.
- Per-cue progress (e.g., `[3/150] Synthesizing cue 3...`).
- Total processing time upon completion.

#### Scenario: Progress output format
- **WHEN** processing a file with 150 cues
- **THEN** each cue synthesis SHALL output a line in the format `[N/150] Synthesizing cue N...`
- **AND** completion SHALL output the total time (e.g., `Completed in 45.2s`)

---

### Requirement: Configuration file
The system SHALL read its configuration from `scripts/_tools/sub-tts/config.ini` with the following sections:

- `[paths]`: `piper_tts_root` (path to piper-tts project), `ffmpeg_executable` (path to ffmpeg.exe), `zid_script` (path to zid.py).
- `[tts_settings]`: `default_lang` (fallback language), `duplicate_mode` (zid-dir | skip | overwrite).
- `[tts_settings]`: `fit_to_subtitle`, `vad_silence_compression`, `vad_max_silence_seconds`, `high_quality_time_stretch`, `max_extra_gap_ms`, `max_speed_factor`.
- `[lang_aliases]`: Optional postfix-to-language overrides (e.g., `ger = de`, `rus = ru`, `eng = en`).

#### Scenario: Config file missing
- **WHEN** `config.ini` does not exist
- **THEN** the system SHALL print an error message referencing `config.ini.template` and exit with code 1

#### Scenario: Custom alias mapping
- **WHEN** `config.ini` contains `[lang_aliases]` with `ger = de`
- **AND** the input file is `video.ger.srt`
- **THEN** the system SHALL resolve language `de`

---

### Requirement: Windows SendTo integration
The system SHALL provide an `install.py` script that creates a Windows "Send to" shortcut named "Kardenwort Sub TTS".

The shortcut SHALL accept one or more `.srt` files dropped via the Windows Explorer "Send to" context menu and invoke `sub_tts.py` with those files as arguments.

The shortcut SHALL use `python.exe` and keep a visible console window open after completion so progress, timing warnings, and error diagnostics can be read.

#### Scenario: SendTo installation
- **WHEN** the user runs `python install.py`
- **THEN** a shortcut named "Kardenwort Sub TTS.lnk" SHALL be created in the user's SendTo directory
- **AND** the shortcut SHALL target `python.exe` with `sub_tts.py --sendto --pause` as arguments

#### Scenario: Multiple file SendTo
- **WHEN** the user selects 3 SRT files and uses "Send to" → "Kardenwort Sub TTS"
- **THEN** the system SHALL process all 3 files sequentially, generating one MP4 per SRT file

---

### Requirement: CLI interface
The system SHALL support direct CLI invocation with the following arguments:
- Positional: one or more SRT file paths.
- `--lang`: Override language detection (bypass postfix detection).
- `--output-dir`: Override output directory.
- `--ffmpeg-path`: Override FFmpeg path from config.

#### Scenario: CLI with explicit language
- **WHEN** invoked as `python sub_tts.py --lang de video.srt`
- **THEN** the system SHALL use language `de` regardless of the filename postfix

#### Scenario: CLI with multiple files
- **WHEN** invoked as `python sub_tts.py video.de.srt lesson.ru.srt`
- **THEN** the system SHALL process both files, detecting language per-file from postfix

