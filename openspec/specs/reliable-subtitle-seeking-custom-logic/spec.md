# Spec: Reliable Subtitle Seeking (Custom Logic)

## Context
Native `sub-seek` can be unreliable when paused near subtitle boundaries.

## Requirements
- Implement `cmd_dw_seek_delta(delta)` to handle subtitle jumps.
- Use the internal `Tracks.pri.subs` table to find the target subtitle index based on current time and delta.
- Execute the jump using `mp.commandv("seek", timestamp, "absolute", "exact")`.
- This logic must replace the default `a`/`d` bindings while the Drum Window is active.

## Verification
- Pause the video near the end of a subtitle (simulating an autopause).
- Press `d`.
- Verify the player immediately jumps to the start of the next subtitle on the first press.
- Repeat for `a` and verify backward navigation.

## ADDED Requirements (from 20260427161414-fix-subtitle-scroll-stuck)

### Requirement: Granular Subtitle Event Preservation
The system MUST ensure that non-consecutive subtitle segments with identical text are preserved as distinct entries in the internal `subs` table. Merging of identical text is ONLY permitted for strictly consecutive segments.

#### Scenario: Repetitive tag preservation
- **WHEN** the subtitle file contains `[Music]` (Segment A), followed by `and fifteen` (Segment B), followed by `[Music]` (Segment C)
- **THEN** the internal `subs` table MUST contain three distinct entries (A, B, and C) to ensure Segment C remains a valid seek target.

### Requirement: Temporal Merging Guard
Subtitle segments with identical text SHALL only be merged if they are temporally adjacent or overlapping (gap <= 200ms).

#### Scenario: Distant duplicate tags
- **WHEN** Segment A (`[Music]`) ends at 00:01:58 and Segment B (`[Music]`) starts at 00:02:03
- **THEN** Segment B SHALL NOT be merged into Segment A, as the temporal gap (5s) exceeds the 200ms threshold.

### Requirement: Guaranteed Subtitle Index Ordering
All internal subtitle tracks MUST be explicitly sorted by start time after parsing to ensure the integrity of the binary search algorithm used for seeking.

#### Scenario: Out-of-order SRT parsing
- **WHEN** an SRT file contains segments that are slightly out of chronological order
- **THEN** the system MUST sort the resulting table before use to prevent navigation deadlocks.
