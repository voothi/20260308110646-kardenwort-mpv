# Spec: Input Configuration Migration

## Context
Standardizing `input.conf` to use custom bindings ensures the best user experience.

## Requirements
- Update `input.conf` to replace `no-osd sub-seek 1` with `script-binding kardenwort/kardenwort-seek_next` (and similarly for `-1` / `prev`).
- Apply these changes to the following keys:
    - `a` / `d` (English)
    - `ф` / `в` (Russian)
- Ensure no conflicting native `sub-seek` bindings remain for these keys.

## Verification
- Press `d` during playback and verify the custom logic is triggered.
- Verify that the OSD feedback (if any) matches the new script-binding behavior.


