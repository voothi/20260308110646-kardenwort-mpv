## 1. Project Scaffolding

- [ ] 1.1 Create directory structure `scripts/_tools/sub-tts/` with `__init__.py` placeholder
- [ ] 1.2 Create `config.ini.template` with all sections (`[paths]`, `[tts_settings]`, `[lang_aliases]`) and documented defaults
- [ ] 1.3 Create `config.ini` (gitignored) populated with paths matching the current development environment

## 2. SRT Parser

- [ ] 2.1 Implement `parse_srt(filepath)` function that returns a list of cue dicts `{index, start_ms, end_ms, text}`
- [ ] 2.2 Implement SRT text sanitization: strip HTML tags (`<i>`, `<b>`, etc.) and ASS override tags (`{\an8}`, `{\c}`, etc.)
- [ ] 2.3 Handle edge cases: BOM-prefixed files, empty cues, multi-line cue text

## 3. Language Detection

- [ ] 3.1 Implement `detect_language(filename, config)` that extracts the postfix from the filename and resolves it to a Piper language code
- [ ] 3.2 Implement alias normalization (e.g., `eng` → `en`, `ger` → `de`, `rus` → `ru`) from `[lang_aliases]` config section
- [ ] 3.3 Validate detected language against Piper TTS config — error out with clear message if unsupported

## 4. Per-Cue TTS Synthesis

- [ ] 4.1 Implement `synthesize_cue(text, lang, output_wav_path, piper_config)` that calls `piper_tts.py --lang <lang> --text <text> --output-file <path>`
- [ ] 4.2 Create temporary directory management: generate temp dir per SRT file, name WAV files sequentially (`cue_001.wav`, etc.)
- [ ] 4.3 Add progress reporting: print `[N/total] Synthesizing cue N...` for each cue
- [ ] 4.4 Handle Piper subprocess errors: capture stderr, report failed cue index and text

## 5. Timed Audio Assembly

- [ ] 5.1 Implement silence gap calculation from SRT timings: compute silence duration between each cue's expected start and the previous cue's audio end
- [ ] 5.2 Build FFmpeg concat filter or file list that interleaves per-cue WAVs with generated silence segments
- [ ] 5.3 Handle overlapping cues: when synthesized audio overflows into next cue's time slot, defer the next cue's start (graceful overflow)
- [ ] 5.4 Generate the final assembled WAV (or pipe directly to the MP4 muxing step)

## 6. MP4 Output Generation

- [ ] 6.1 Implement FFmpeg command builder for black canvas + audio muxing (match Convert Media encoding parameters)
- [ ] 6.2 Implement output path resolution: `<basename>.mp4` in same directory, with ZID-dir duplicate handling
- [ ] 6.3 Integrate ZID generation (call `zid.py --no-clipboard` or fallback to `datetime.now()`)

## 7. Cleanup and Error Handling

- [ ] 7.1 Implement temporary file cleanup after successful MP4 generation
- [ ] 7.2 Preserve temp files on failure with diagnostic message including temp directory path
- [ ] 7.3 Add comprehensive error handling: missing config, missing FFmpeg, missing Piper, invalid SRT

## 8. CLI Interface

- [ ] 8.1 Implement `argparse` CLI with positional SRT file args and optional `--lang`, `--output-dir`, `--ffmpeg-path` overrides
- [ ] 8.2 Add `--sendto` mode for Windows SendTo integration (accept file paths as positional arguments)
- [ ] 8.3 Report total processing time on completion

## 9. Windows SendTo Installer

- [ ] 9.1 Create `install.py` following the Sub Viewer pattern: create "Kardenwort Sub TTS.lnk" in SendTo directory
- [ ] 9.2 Target `pythonw.exe` with `sub_tts.py` as argument, configure shortcut with minimized window style

## 10. Verification

- [ ] 10.1 Manual test: process a short `.de.srt` file (3-5 cues) and verify the output MP4 has correct timing
- [ ] 10.2 Manual test: process a `.ru.srt` file to verify language auto-detection
- [ ] 10.3 Manual test: process a file without language postfix to verify default language fallback
- [ ] 10.4 Manual test: verify duplicate handling — run twice on the same file, confirm ZID-dir creation
- [ ] 10.5 Manual test: verify SendTo shortcut works from Windows Explorer
