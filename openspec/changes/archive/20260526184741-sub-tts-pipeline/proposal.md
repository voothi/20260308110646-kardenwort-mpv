## Why

The current workflow for generating TTS audio from subtitle files requires manually loading files into Subtitle Edit, selecting the Piper engine and voice, and running "Text to speech and add to video..." / "Generate speech from text". This is tedious, especially with multiple language-specific subtitle files (`.ru.srt`, `.de.srt`, etc.) that each require manually selecting the correct Piper voice model.

A standalone pipeline tool — integrated via Windows "Send to" like the existing Sub Viewer and Convert Media tools — would automate the entire flow: detect the language from the subtitle file's postfix, invoke Piper TTS for each subtitle entry, and produce a final `.mp4` with the synthesized speech audio, all without opening Subtitle Edit.

## What Changes

- **New standalone Python tool**: `scripts/_tools/sub-tts/sub_tts.py` — a pipeline that:
  1. Accepts one or more `.srt` subtitle files (via drag-and-drop or SendTo).
  2. Detects the language from the filename postfix (e.g., `.ru.srt` → `ru`, `.de.srt` → `de`).
  3. Parses each subtitle entry (text + timing).
  4. Calls `piper_tts.py` (from `20241206010110-piper-tts`) for each subtitle entry to generate per-cue WAV files.
  5. Concatenates the WAV files with silence gaps matching the SRT timing.
  6. Calls `convert_media.py` (from `20241213164711-convert-media`) or directly invokes FFmpeg to produce the final `.mp4` (black canvas + synthesized audio).
- **New installer**: `scripts/_tools/sub-tts/install.py` — creates a Windows "Send to" shortcut, following the same pattern as Sub Viewer's `install.py`.
- **Language-to-model auto-detection**: Reads the Piper TTS `config.ini` to resolve which voice model to use based on the subtitle file's language postfix.
- **Config file**: `scripts/_tools/sub-tts/config.ini` — local configuration pointing to external project paths (piper-tts root, ffmpeg path) and language postfix mapping overrides.

## Capabilities

### New Capabilities
- `sub-tts-pipeline`: End-to-end pipeline that converts subtitle files to MP4 video with synthesized speech audio, using language auto-detection from filename postfix and Piper TTS as the synthesis engine.

### Modified Capabilities
_(none — this is a new standalone tool that doesn't alter existing specs)_

## Impact

- **New files** in `scripts/_tools/sub-tts/` directory (new tool, self-contained).
- **External dependencies**: References `piper_tts.py` from the `20241206010110-piper-tts` project and `convert_media.py` from the `20241213164711-convert-media` project. These are called as external processes — no source modifications to those projects.
- **FFmpeg**: Required as a runtime dependency (already present in the user's environment via convert-media).
- **No changes** to the mpv Lua scripts, sub-viewer, or any existing Kardenwort core code.
