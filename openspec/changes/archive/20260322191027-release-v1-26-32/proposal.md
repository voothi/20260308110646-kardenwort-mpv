# Proposal: Improved Drum Window Navigation & Pointer Logic (v1.26.32)

## Problem
The Drum Window's word-level pointer was active by default, sometimes interfering with full-line copy operations. Additionally, the native mpv `sub-seek` command exhibited inconsistent behavior when the player was paused near the end of a subtitle (common during autopauses), requiring multiple keypresses to jump to the next line.

## Proposed Change
Refine the Drum Window pointer behavior to be inactive by default and implement a custom, table-based seeking logic to ensure reliable subtitle navigation.

## Objectives
- Improve the initial user experience in the Drum Window by deactivating the word pointer until needed.
- Ensure that full-line copying is the primary interaction mode upon window opening.
- Resolve the "double-tap" requirement for subtitle jumps after autopauses.
- Synchronize pointer state with scrolling and search actions.

## Key Features
- **Deactivated Pointer by Default**: `DW_CURSOR_WORD` starts at `-1`.
- **Auto-Deactivation Triggers**: Scrolling and search jumps reset the word selection.
- **Reliable Subtitle Seeking**: Custom `cmd_dw_seek_delta` logic using pre-loaded subtitle tables.
- **Explicit Pointer Activation**: Arrow keys wake up the word selection engine.
