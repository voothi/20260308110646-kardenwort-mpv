# Proposal: Fix Copy Subtitle Fragility

## Problem Statement
The `copy-subtitle` global command (Standard Mode) currently relies on `mp.get_property("sub-text")` to retrieve subtitle text. This property is unreliable because:
1. Native subtitle visibility is explicitly disabled when using custom OSD rendering (Drum Mode, styled SRTs).
2. Consequently, `copy-subtitle` fails (returns "No subtitle to copy") when Context Copy is OFF, even if a subtitle is clearly visible on the OSD.
3. Users report that copying only works if Context Copy is ON (which triggers a file reload/internal check) or if a specific word is highlighted in the Drum Window (which uses a separate, more robust command).

## Proposed Change
Refactor `cmd_copy_sub` to prioritize internal subtitle tracks (`Tracks.pri.subs` and `Tracks.sec.subs`) over native properties. By using the same logic as the Context Copy and Drum Window systems, we ensure that "What You See Is What You Copy" across all UI modes.

## Impact
- **Reliability**: Copying subtitles will work consistently in all modes, including "White Subtitles" (SRT OSD) and Regular Mode.
- **Performance**: Removes redundant `mp.get_property` calls in favor of already-loaded internal data.
- **Consistency**: Aligns Standard Mode copy behavior with Drum Window copy behavior.
