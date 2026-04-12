# Proposal: Unified Smooth Subtitle Navigation

**ZID**: 20260412131945
**Status**: Proposed
**Change Name**: smooth-nav-repeat

## Problem
Currently, subtitle navigation using the `a` and `d` keys (including their Russian equivalents `ф` and `в`) is inconsistent across different operating modes. 
- In **Window Mode (`w`)**, keys are repeatable but rely on native OS settings, which can be unstable or jerky.
- In **Drum Mode (`c`)** and **Normal Mode**, keys do not repeat at all, requiring the user to tap them repeatedly to move through several subtitles.
- There is no central way for the user to configure the repeat delay or speed.

## What Changes
We will implement a unified, script-based "Hold-to-Scroll" engine within `lls_core.lua`. This engine will:
- Listen for both key-down and key-up events using complex bindings.
- Implement a custom auto-repeat timer with configurable delay and rate.
- Replace the legacy `repeatable` flag in mode-specific bindings to ensure a consistent feel throughout the application.

## Capabilities

### New Capabilities
- `nav-auto-repeat`: Provides a global, configurable auto-repeat mechanism for subtitle seeking and navigation keys.

### Modified Capabilities
- `drum-window`: Enhances navigation stability within the Drum Window by replacing native repeat with the new unified engine.
- `drum-mode`: Enables hold-to-scroll functionality which was previously missing in this mode.

## Impact
- **lls_core.lua**: Significant logic updates to key binding registration and event handling.
- **Options**: Addition of `seek_hold_delay` and `seek_hold_rate` parameters.
- **Input Experience**: Smoother, faster navigation through long subtitle tracks in all modes.
