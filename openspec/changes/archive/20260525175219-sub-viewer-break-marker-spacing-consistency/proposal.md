## Why

Recent text-to-SRT reader workflows produced inconsistent break-marker behavior: generated `.srt` cues could contain ASS-style `\N`, and downstream normalization introduced synthetic spacing that rendered differently in DW, DM, and tooltip overlays. This created visible reading regressions and made dual-track text playback less predictable.

## What Changes

- Normalize Sub Viewer reader cue output to emit real SRT line breaks instead of ASS-style `\N` markers.
- Define spacing-safe break-marker handling so escaped break markers from legacy subtitle text do not create synthetic double spaces around wrapped boundaries.
- Align rendering-path behavior across DW, DM, and tooltip text preparation so forced line boundaries and adjacent tokens (including hyphenated terms) remain consistent.
- Add targeted unit regression coverage for reader generation and paired text workflows to prevent `\N` reintroduction and spacing drift.
- Harden script initialization expectations so hotfixes for text normalization cannot reintroduce Lua compile failures during startup.

## Capabilities

### New Capabilities

- None.

### Modified Capabilities

- `sub-viewer`: Reader `.txt/.md/.rst/.log` conversion requirements now enforce real SRT newline output and spacing-safe cue text for single and paired inputs.
- `subtitle-rendering`: Text normalization requirements now cover escaped break-marker handling and spacing consistency across DW, DM, and tooltip preparation paths.
- `script-stability-hardening`: Startup stability requirements now include compile-safe script initialization constraints for Lua chunk-local limits.

## Impact

- Affects `scripts/_tools/sub-viewer/viewer.py` reader cue generation and paired text conversion output.
- Affects `scripts/kardenwort/main.lua` break-marker normalization and multi-path text preparation used by DW/DM/tooltip/copy/search rendering flows.
- Affects `tests/unit/test_sub_viewer_unit.py` with regression coverage for newline marker output and hyphen-sensitive spacing consistency.
