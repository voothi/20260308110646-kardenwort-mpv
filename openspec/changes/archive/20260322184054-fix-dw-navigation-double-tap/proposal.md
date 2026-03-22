# Proposal: Fix Drum Window Navigation Double-Tap

## Summary
Resolve the issue where the `d` key (next subtitle) requires two presses to navigate when the video is paused near the end of a subtitle (typical after an autopause).

## Problem
The Drum Window currently uses the built-in `sub-seek` command for `a`/`d` navigation. When the video is paused at the "pause padding" threshold (0.15s before the end), `sub-seek 1` often remains on the current subtitle or behaves inconsistently, requiring a second press to jump to the actual next line.

## Proposed Solution
Bypass the native `sub-seek` command in `manage_dw_bindings`. Instead, use the internal `Tracks.pri.subs` table to calculate the exact start time of the next/previous subtitle relative to the current playback position and perform an `absolute+exact` seek.

## Benefits
-   **Immediate Response**: Navigation happens on the first press regardless of the current pause state or padding.
-   **Consistency**: `a` and `d` will behave identically in terms of reliability.
-   **Precision**: Using the internal subtitle table ensures we always jump to the exact expected line.
