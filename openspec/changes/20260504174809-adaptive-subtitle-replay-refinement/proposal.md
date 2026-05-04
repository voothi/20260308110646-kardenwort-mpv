# Proposal: Unified Adaptive Replay (Flashback)

**ID**: 20260504174809-adaptive-subtitle-replay-refinement
**Author**: Antigravity
**Date**: 2026-05-04
**ZID**: 20260504184237

## Overview
This change implements a high-performance, subtitle-independent replay system (Flashback) that works across all study modes. It resolves hardware ghosting issues and provides a unified interface for phrase repetition.

## Motivation
- **Cognitive Efficiency**: Allow users to repeat the most recent phrase regardless of subtitle length.
- **Immersion Continuity**: Prevent OSD noise and unnecessary stops during streaming study.
- **Hardware Stability**: Neutralize keyboard matrix ghosting via temporal state validation.

## Dialogue Anchors & References
- 20260504173340: Purpose definition (load reduction, one key).
- 20260504175320: Implementation start.
- 20260504180213: Decision to remove subtitle boundaries (Track Range logic).
- 20260504180815: Unified loop count requirement.
- 20260504181434: Refinement of default replay window (2000ms).
- 20260504181647: Discovery and fix for Autopause interference during cross-subtitle replay.
- 20260504182015: Simplification of Autopause OFF behavior (Flashback mode).
- 20260504183134: Implementation of `replay_autostop` parameter to allow fluid context replay in Autopause ON mode.

## Core Features
1. **Flashback**: Single-key `S` jumps back `X` ms and replays `N` times.
2. **Flexible Completion**: Adjustable `replay_autostop` to decide between a hard stop or continuing the line.
3. **Mode-Adaptivity**: Continuous streaming in Immersion Mode.
4. **Sticky Hold Recovery**: Automatic state correction for dropped spacebar signals.
