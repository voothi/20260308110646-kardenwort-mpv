## 1. Project Scaffolding

- [x] 1.1 Create directory structure `scripts/_tools/sub-tts/` with `__init__.py` placeholder
- [x] 1.2 Create `config.ini.template` with all sections (`[paths]`, `[tts_settings]`, `[lang_aliases]`) and documented defaults
- [x] 1.3 Create `config.ini` (gitignored) populated with paths matching the current development environment

## 2. SRT Parser

- [x] 2.1 Implement `parse_srt(filepath)` function that returns a list of cue dicts `{index, start_ms, end_ms, text}`
- [x] 2.2 Implement SRT text sanitization: strip HTML tags (`<i>`, `<b>`, etc.) and ASS override tags (`{\an8}`, `{\c}`, etc.)
- [x] 2.3 Handle edge cases: BOM-prefixed files, empty cues, multi-line cue text

## 3. Language Detection

- [x] 3.1 Implement `detect_language(filename, config)` that extracts the postfix from the filename and resolves it to a Piper language code
- [x] 3.2 Implement alias normalization (e.g., `eng` → `en`, `ger` → `de`, `rus` → `ru`) from `[lang_aliases]` config section
- [x] 3.3 Validate detected language against Piper TTS config — error out with clear message if unsupported

## 4. Per-Cue TTS Synthesis

- [x] 4.1 Implement `synthesize_cue(text, lang, output_wav_path, piper_config)` that calls `piper_tts.py --lang <lang> --text <text> --output-file <path>`
- [x] 4.2 Create temporary directory management: generate temp dir per SRT file, name WAV files sequentially (`cue_001.wav`, etc.)
- [x] 4.3 Add progress reporting: print `[N/total] Synthesizing cue N...` for each cue
- [x] 4.4 Handle Piper subprocess errors: capture stderr, report failed cue index and text

## 5. Timed Audio Assembly

- [x] 5.1 Implement silence gap calculation from SRT timings: compute silence duration between each cue's expected start and the previous cue's audio end
- [x] 5.2 Build FFmpeg concat filter or file list that interleaves per-cue WAVs with generated silence segments
- [x] 5.3 Handle overlapping cues: when synthesized audio overflows into next cue's time slot, defer the next cue's start (graceful overflow)
- [x] 5.4 Generate the final assembled WAV (or pipe directly to the MP4 muxing step)

## 6. MP4 Output Generation

- [x] 6.1 Implement FFmpeg command builder for black canvas + audio muxing (match Convert Media encoding parameters)
- [x] 6.2 Implement output path resolution: `<basename>.mp4` in same directory, with ZID-dir duplicate handling
- [x] 6.3 Integrate ZID generation (call `zid.py --no-clipboard` or fallback to `datetime.now()`)

## 7. Cleanup and Error Handling

- [x] 7.1 Implement temporary file cleanup after successful MP4 generation
- [x] 7.2 Preserve temp files on failure with diagnostic message including temp directory path
- [x] 7.3 Add comprehensive error handling: missing config, missing FFmpeg, missing Piper, invalid SRT

## 8. CLI Interface

- [x] 8.1 Implement `argparse` CLI with positional SRT file args and optional `--lang`, `--output-dir`, `--ffmpeg-path` overrides
- [x] 8.2 Add `--sendto` mode for Windows SendTo integration (accept file paths as positional arguments)
- [x] 8.3 Report total processing time on completion

## 9. Windows SendTo Installer

- [x] 9.1 Create `install.py` following the Sub Viewer pattern: create "Kardenwort Sub TTS.lnk" in SendTo directory
- [x] 9.2 Use `python.exe` with visible window (`WindowStyle=1`) and `--pause` flag so user can read progress before closing

## 10. Verification

- [ ] 10.1 Manual test: process a short `.de.srt` file (3-5 cues) and verify the output MP4 has correct timing
- [ ] 10.2 Manual test: process a `.ru.srt` file to verify language auto-detection
- [ ] 10.3 Manual test: process a file without language postfix to verify default language fallback
- [ ] 10.4 Manual test: verify duplicate handling — run twice on the same file, confirm ZID-dir creation
- [ ] 10.5 Manual test: verify SendTo shortcut works from Windows Explorer (window visible, steps readable)

## 11. Bugfixes (20260526192510)

- [x] 11.1 **Output filename**: strip language postfix from output name (`video.de.srt` → `video.mp4`, not `video.de.mp4`)
- [x] 11.2 **Console window**: switch install.py from `pythonw.exe` (hidden) to `python.exe` + `WindowStyle=1` + `--pause` flag; window stays open until user presses Enter
- [x] 11.3 **Audio sync**: fix concat builder — anchor each cue WAV at its exact `start_ms` from SRT (not at running `cursor_ms`); prevents cumulative drift when previous cue's audio runs long
- [x] 11.4 **Audio sync v2**: replaced `concat` filter completely with an `amix` batch approach because `concat` physically appends (preventing true overlaps). Now every cue is individually anchored to a silent base track using `adelay` for perfect absolute timing, regardless of TTS audio length.

## 12. Sync Review and Test Hardening (20260526195053)

- [x] 12.1 **Critical review**: identify the impossible timing contract: exact SRT starts, no overlap, and no subtitle retiming cannot all be true when synthesized speech is longer than the cue window
- [x] 12.2 **Spec correction**: update design/spec wording from concat/graceful-defer behavior to explicit subtitle-locked absolute-start behavior with overflow diagnostics
- [x] 12.3 **Pure timing plan**: extract timing placement into `build_audio_placement_plan()` so cue placement and overflow can be unit-tested without running Piper or FFmpeg
- [x] 12.4 **Unit tests**: add tests for SRT parsing, language alias/default resolution, postfix-free MP4 output naming, and timing overflow detection
- [ ] 12.5 **Diagnostic run**: process the problem SRT with the updated warning output and record overflow count/largest overflow in `docs/conversation.log`
- [x] 12.6 **Decision point**: choose the final sync policy for overflowing cues: use Subtitle Edit-style subtitle-locked fit as the default
- [x] 12.7 **Implement chosen policy**: add config-driven `fit_to_subtitle` speed stage with trim, optional VAD silence compression, rubberband/atempo speed-up, and max speed cap
- [ ] 12.8 **Media-level verification**: verify with ffprobe/ffmpeg on a short fixture and manually compare generated MP4 with matching subtitles
- [x] 12.9 **Subtitle Edit parity research**: inspect `TextToSpeechViewModel.FixSpeed`, `ReviewSpeechViewModel.TrimAndAdjustSpeed`, and `FfmpegGenerator` helpers from `U:\voothi\20260517160217-subtitleedit`
