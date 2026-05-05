# OpenSpec: Directional Seek OSD

**ID**: 20260505162601-centered-seek-osd
**ZID**: 20260505201004
**Status**: Implementation Complete

## Objective
Implement a professional, directional On-Screen Display (OSD) feedback system for relative time-based seeking. The system provides visual confirmation of seek direction, cumulative session tracking (YouTube-style), and granular styling controls consistent with the Kardenwort immersion suite.

## What Changes

### 1. Directional Feedback System
- **Dynamic Positioning**: OSD messages appear on the left (`{\an4}`) for backward seeks and on the right (`{\an6}`) for forward seeks.
- **Fixed Vertical Anchor**: Messages are vertically centered on the screen to avoid overlap with subtitle tracks.
- **Dedicated Overlay**: Uses a dedicated `mp.create_osd_overlay("ass-events")` with a fixed resolution (derived from `Options.font_base_height`) to ensure consistent scaling across all monitor resolutions.

### 2. YouTube-Style Cumulative Accumulator
- **Intelligent Tracking**: Tracks consecutive seeks within a configurable window (`seek_osd_duration`).
- **Cumulative Display**: Displays the total skipped distance for the current session (e.g., `+2` -> `+4` -> `+6`) instead of just the increment.
- **Directional Reset**: Instantly resets the accumulator if the seek direction changes (e.g., skips forward then skips back).
- **Session Indication**: The OSD duration acts as an "active rewind/forward session" indicator.

### 3. Granular Styling & Templates
- **Configurable Styles**: Full suite of parameters in `mpv.conf` (font, size, color, background opacity, border, shadow).
- **Format Templates**:
    - `seek_msg_format`: Template for single/disconnected seeks (e.g., `%p%v`).
    - `seek_msg_cumulative_format`: Template for cumulative sessions (e.g., `%P%V`).
    - **Placeholders**: Support for `%p` (instant prefix), `%v` (instant value), `%P` (acc prefix), and `%V` (acc value).
- **Robust Replacement**: Table-based `gsub` engine to handle `%` placeholders reliably.

### 4. Architectural Integration
- **Options Alignment**: All styling and logic parameters are exposed via `Options` and synchronized with `mp.options.read_options`.
- **Global Resolution**: Derives `res_x` and `res_y` from `Options.font_base_height` to eliminate hardcoding and ensure suite-wide UI consistency.
- **Scoped UI Pointers**: Properly forward-declared and scoped OSD overlay and timer objects.

## Technical Details
- **Logic File**: `scripts/lls_core.lua`
- **Command Handling**: `cmd_seek_time` manages the state machine (Accumulator, Direction, Timer).
- **Rendering**: `show_seek_osd` handles ASS-based rendering using the dedicated overlay.
- **Configuration**: `mpv.conf` holds all user-tunable parameters under the `lls-` prefix.
