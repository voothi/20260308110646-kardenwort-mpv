# Proposal: Audio Padding Sentinel (ZID: 20260505021903)

## Goal
Implement a robust "Audio Padding" system that allows users to hear the full onset and tail of a phrase by adding configurable buffers (pre-roll and post-roll) to subtitle boundaries.

## Problem
Current subtitle navigation and autopausing are tied to strict technical boundaries. This leads to:
1. **Audio Clipping**: The beginning or end of words are often cut off because the player seeks exactly to the start or pauses exactly at the end.
2. **Context Hijacking**: In `Autopause ON` mode, if subtitles are close together, the script "snaps" to the next subtitle before the previous one's tail has finished. This causes the script to lose reference to the previous subtitle's boundary, resulting in the player "skipping" the stop.

## Proposed Solution
Introduce `audio_padding_start` and `audio_padding_end` (in milliseconds) as user-configurable options in `mpv.conf`.
Upgrade the script's heartbeat loop to use a **State-Locked Sentinel** logic:
- The script "locks" onto a subtitle the moment it becomes active.
- It maintains focus on this subtitle throughout its technical duration PLUS the configured `audio_padding_end`.
- It refuses to "snap" to the next subtitle until the padding for the current one has expired or a manual seek occurs.

## Expected Outcomes
- **Navigation**: Seeking with `a`/`d`, `Enter`, or Double-Click will land `audio_padding_start` ms before the subtitle.
- **Autopause**: The player will pause at `end + audio_padding_end`, ensuring the full audio tail is heard.
- **Visuals**: The on-screen highlight will persist until the audio tail finishes, providing better feedback.
