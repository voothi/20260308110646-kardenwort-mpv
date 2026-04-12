# Proposal: Fix Startup Navigation Latency

**ZID**: 20260412135354
**Status**: Proposed
**Change Name**: fix-startup-nav-latency

## Problem
Currently, the navigation keys (`a`/`d`) are "dormant" when a video is first started in Normal Mode. They only become active after the user enters Drum Mode (`c`) or Window Mode (`w`) at least once. 
This is because subtitle data is lazily loaded into the script's memory only when specialized modes are activated, but the new global `a`/`d` logic requires this data to function.

## What Changes
We will move the subtitle memory initialization logic from mode-specific toggles into the core `update_media_state()` function. This ensures that as soon as a subtitle track is identified at startup, its data is loaded and the navigation keys are immediately functional in all modes.

## Capabilities

### Modified Capabilities
- `nav-auto-repeat`: Ensures this capability is active from the moment of playback start.

## Impact
- **lls_core.lua**: Move logic from `update_media_state` (inside Drum-only block) and `cmd_toggle_drum_window` to the shared `update_media_state` track-detection block.
- **UX**: Eliminates the "keys don't work" confusion at the start of a session.
