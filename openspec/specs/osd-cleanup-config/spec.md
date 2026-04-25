# Spec: OSD Cleanup Configuration

## Context
The default mpv OSD bar and inconsistent border styles cluttered the interface.

## Requirements
- Set `osd-bar=no` in `mpv.conf`.
- Standardize `osd-border-style=outline-and-shadow` for Drum Mode to ensure readability across all backgrounds.
- Ensure the progress bar only appears when explicitly toggled (e.g., via OSC).

## Verification
- Confirm that jumping between subtitles (`a`/`d`) does not trigger the OSD bar.
- Verify that the subtitle text has a consistent outline and shadow in Drum Mode.
