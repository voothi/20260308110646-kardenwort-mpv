# Proposal: Universal Navigation Reliability (v1.26.34)

## Problem
The native mpv `sub-seek` command continued to exhibit inconsistent behavior in "windowless mode" (standard playback), especially when jumping after an autopause. This required a "double-tap" from the user to move to the next subtitle.

## Proposed Change
Extend the high-precision, table-based seeking logic used in the Drum Window to the entire player by exposing it via global script-bindings and updating the default keybindings.

## Objectives
- Achieve "one-tap" subtitle navigation reliability across all player states.
- Unify the navigation architecture to use a single source of truth (`Tracks.pri.subs`).
- Standardize the keybinding configuration in `input.conf` to use custom script-bindings.
- Maintain full support for English and Russian keyboard layouts.

## Key Features
- **Global Navigation Bindings**: New `lls-seek_prev` and `lls-seek_next` bindings.
- **Unified Navigation Logic**: High-precision seeking regardless of whether custom UI is visible.
- **Input Map Migration**: Transition from native `sub-seek` to `script-binding` in `input.conf`.
- **Improved Responsiveness**: Instant jumps on the first keypress.
