# Proposal: Refining Drum Window Selection

## Problem
In the Drum Window (`w` mode), the word selection mechanism (yellow highlighting) fails when navigating across subtitle line boundaries using the keyboard (arrows). Specifically, the selection anchor is currently reset or incorrectly calculated when jumping from the last word of one line to the first word of the next. This prevents users from performing "mass selection" (range highlighting) across multiple lines smoothly. Additionally, navigation jump distances (5 words/lines) are hardcoded, limiting user customization.

## Solution
Implement a robust anchor-capture mechanism that snapshots the current cursor position immediately before any movement. Update the movement logic to maintain this anchor when the `Shift` key is held, regardless of line transitions. Expose the hardcoded jump distances as configurable parameters in the global `Options` state and MPV configuration.

## Objectives
- Implement pre-move anchor capture for reliable multi-line selection.
- Restrict range selection triggers to `Shift` and `Ctrl+Shift` arrow combinations.
- Expose `dw_jump_words` and `dw_jump_lines` as configurable parameters.
- Update `mpv.conf` and `input.conf` to reflect new parameters and capabilities.
