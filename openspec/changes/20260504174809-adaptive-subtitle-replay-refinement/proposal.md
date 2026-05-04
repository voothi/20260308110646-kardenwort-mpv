# Proposal: Adaptive Subtitle Replay Refinement

**ID**: 20260504174809-adaptive-subtitle-replay-refinement
**Author**: Antigravity
**Date**: 2026-05-04
**ZID**: 20260504174809

## Overview
This change refines the `S` (and `ы`) key replay functionality to meet advanced user needs for cognitive load reduction and precise pronunciation study. It transitions the feature from a simple "whole-subtitle" replay to an adaptive "segment-based" replay with support for multiple iterations and robust hardware ghosting resistance.

## Motivation
1. **Cognitive Load**: Repeating long subtitles from the beginning can be inefficient. Users often need to re-listen only to the most recent phrase.
2. **Hardware Constraints**: Keyboard matrix ghosting causes desynchronization between the physical spacebar state and the script's FSM, leading to "stuck" playback.
3. **Study Efficiency**: Support for a configurable `repeat_count` allows for automated drilling of a single line.

## Proposed Changes
1. **Adaptive Segment Logic**:
   - Introduce `Options.replay_fixed_ms` (ms).
   - If `replay_fixed_ms > 0`, the replay start point is calculated as `math.max(sub.start_time, current_time - replay_fixed_ms/1000)`.
   - This ensures that for long subtitles, we only jump back a short duration while still respecting the subtitle's logical start.

2. **Repeat Count (Iterations)**:
   - Introduce `Options.replay_count` (integer).
   - The script will track the remaining iterations in `FSM.REPLAY_ITERATIONS`.
   - In `Autopause ON` mode, the player will replay the segment `N` times before finally pausing.

3. **Ghosting-Resistant Sync (State Recovery)**:
   - Introduce `FSM.GHOST_HOLD_EXPIRY`.
   - When a "Sticky Hold" is forced (due to suspected ghosting at the moment of pressing `S`), the hold state is given a 2-second time-to-live (TTL).
   - If no "real" Space DOWN event is received within this TTL, the FSM will automatically revert to `IDLE` at the next subtitle boundary (or earlier), ensuring that a physical release of the spacebar is eventually honored even if the "UP" event was dropped.

## Dialogue Anchors & References
- 20260504173340: Definition of purpose (relieving load, ms config, context size).
- 20260504171059: Report of playback continuing desync after spacebar release.
- 20260504021350: Initial "Ghost Release" hypothesis and Sticky Hold implementation.

## User Impact
- **S Key**: Single-shot replay (Autopause ON) or Persistent Loop (Autopause OFF).
- **Smooth Navigation**: `a`/`d` keys continue to work harmoniously, updating loop boundaries.
- **Robust Semi-Automatic Mode**: Space-hold streaming works reliably across replays without getting stuck.
