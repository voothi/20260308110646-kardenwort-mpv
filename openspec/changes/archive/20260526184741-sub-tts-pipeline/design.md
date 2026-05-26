## Context

The Kardenwort ecosystem already has two "Send to"–integrated Python tools:

1. **Sub Viewer** (`scripts/_tools/sub-viewer/`) — launches mpv with subtitle files over a black video canvas.
2. **Convert Media** (`U:\voothi\20241213164711-convert-media/`) — converts audio files to MP4 with a black video track via FFmpeg.

Additionally, **Piper TTS** (`U:\voothi\20241206010110-piper-tts/`) provides a CLI for text-to-speech synthesis with multi-language voice model support, configured via `config.ini`.

Currently, generating spoken audio from subtitle files requires Subtitle Edit's "Text to speech and add to video…" GUI feature, which involves manual voice selection per language. The new Sub TTS Pipeline tool will automate this entire flow by combining SRT parsing, Piper TTS synthesis, and FFmpeg muxing into a single script invocable via Windows "Send to".

## Goals / Non-Goals

**Goals:**
- Automate the complete subtitle→speech→video pipeline with a single action (SendTo or CLI).
- Detect the target language automatically from the subtitle filename postfix (e.g., `.de.srt` → `de`, `.ru.srt` → `ru`).
- Reuse the Piper TTS project's existing `config.ini` to resolve voice models — no duplicated model configuration.
- Follow established patterns from Sub Viewer and Convert Media for installation, logging, and error handling.
- Produce a `.mp4` file (black canvas + synthesized audio) placed alongside the source subtitle file.

**Non-Goals:**
- Real-time TTS playback within mpv (this is a batch processing tool, not a live feature).
- Modifications to the Piper TTS or Convert Media projects themselves.
- Support for non-SRT subtitle formats (ASS/VTT can be added later).
- GUI — this is a CLI / SendTo tool, consistent with the existing ecosystem tools.
- Video overlay or subtitle burn-in — the output is audio-only on a black canvas.

## Decisions

### D1: Standalone Script with Cross-Project Invocation

**Decision**: Create `sub_tts.py` as a standalone script that shells out to `piper_tts.py` for each subtitle cue (via `subprocess`), rather than importing Piper's internals.

**Rationale**: This preserves project boundaries and avoids coupling. Piper TTS is a separate repository with its own release cycle. Subprocess invocation is the same pattern used by the Kardenwort mpv plugin's TTS hotkeys.

**Alternative considered**: Importing `piper_tts.py` directly — rejected because it would create a tight dependency and require `pyperclip` to be installed in the caller's environment.

### D2: Per-Cue WAV Generation + Timestamped FFmpeg Assembly

**Decision**: Generate individual WAV files per subtitle cue using Piper TTS's `--output-file` argument, then use FFmpeg to:
1. Place each cue's audio at an explicit timestamp.
2. Mix all timed cue audio into a single WAV.
3. Mux with a black video canvas to produce the final MP4.

**Rationale**: This approach gives precise timing control aligned with the original subtitle timings. Each cue's audio starts at the exact timestamp from the SRT file, with silence filling gaps. This mirrors Subtitle Edit's "Generate speech from text" behavior.

**Alternative considered**: Streaming all text to Piper in one call — rejected because it doesn't provide per-cue timing control and Piper generates continuous audio.

**Rejected implementation detail**: FFmpeg concat-based assembly is not suitable for subtitle-locked timing. Concat appends streams sequentially, so a cue that runs longer than its subtitle window pushes every following cue later and creates cumulative drift.

### D2b: Synchronization Policy Must Be Explicit

**Decision**: Treat sync as a policy decision rather than an implicit side effect of the FFmpeg filter graph.

Current implementation uses a **subtitle-locked / absolute-start** policy:
- Every synthesized cue is anchored to the cue's SRT `start_ms`.
- Later cues are not shifted when earlier synthesized audio is too long.
- Overflow is reported as a timing warning.

**Rationale**: This prevents cumulative drift and makes the generated MP4 comparable to the original subtitle timestamps.

**Trade-off**: If Piper speech is longer than the available subtitle window, exact SRT starts can cause overlapping speech. Avoiding overlap requires either speeding/trimming audio or retiming subtitles.

**Implemented policy**: A measured **fit-to-subtitle** policy modeled after Subtitle Edit's `FixSpeed` stage:
- Trim leading/trailing silence from each generated cue WAV.
- Optionally compress internal silence gaps before changing tempo.
- Allow up to 1000ms of available gap before the next subtitle to reduce unnecessary speed-up.
- If the cue is still too long, calculate `speed_factor = audio_duration / target_duration`.
- Prefer FFmpeg `rubberband=tempo=...` for high-quality pitch-preserving stretch when enabled and available; otherwise use `atempo`.
- Cap automatic speed-up with `max_speed_factor`; remaining overflow is reported by the placement diagnostics.

**Remaining option**: If a cue still cannot fit cleanly after the configured speed cap, a future iteration can emit a retimed `.srt` matching generated narration.

### D3: Language Detection from Filename Postfix

**Decision**: Use the subtitle filename's postfix before the extension to determine language:
- `video.de.srt` → language `de`
- `video.ru.srt` → language `ru`
- `video.srt` (no postfix) → use configured default language

The mapping follows the same `LANG_SUFFIXES` convention already used in `viewer.py`.

**Rationale**: This is the established naming convention in the Kardenwort ecosystem. The Sub Viewer already parses these postfixes for secondary track selection.

### D4: Configuration via Local `config.ini`

**Decision**: The tool has its own `config.ini` that stores:
- Path to the Piper TTS project root (to locate `piper_tts.py` and its `config.ini`).
- Path to FFmpeg executable.
- Default language (fallback when postfix is absent).
- Optional postfix-to-language mapping overrides.

**Rationale**: Keeps the tool self-contained and portable. The user configures paths once at install time.

### D5: Output Placement Policy (Same-Dir, Matching Convert Media)

**Decision**: Output `.mp4` is placed in the same directory as the source `.srt` file, named `<basename-without-language-postfix>.mp4` (e.g., `video.de.srt` → `video.mp4`). Duplicate handling uses ZID-dir policy, identical to Convert Media.

**Rationale**: Consistent with the Convert Media tool's `same-dir` / `zid-dir` defaults.

### D6: SendTo Installation Pattern

**Decision**: Provide `install.py` that creates a Windows SendTo shortcut named "Kardenwort Sub TTS", following the exact pattern from Sub Viewer's `install.py` and Convert Media's `install_sendto_shortcut()`.

**Rationale**: Users already understand this installation pattern from the two existing tools.

## Risks / Trade-offs

- **Processing time for long subtitle files**: A 1-hour subtitle file with 500+ entries will require 500+ Piper subprocess calls. → Mitigation: Show progress (percentage/count) to stdout. Consider batching in a future iteration.
- **Piper TTS project path hardcoded per-machine**: The tool needs to know where `piper_tts.py` lives. → Mitigation: Configurable via `config.ini`; installer can auto-detect from known paths.
- **Large temporary WAV files**: Individual WAV files can consume significant disk space for long subtitles. → Mitigation: Clean up temporary WAV files after successful MP4 generation. Use a temp directory under the output folder.
- **FFmpeg availability**: Required but not bundled. → Mitigation: Auto-detect via `PATH` or read from config, same as Convert Media.
