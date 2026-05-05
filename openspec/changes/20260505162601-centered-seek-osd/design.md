## Context

The current seeking system uses native mpv `seek` commands for time-based navigation (LEFT/RIGHT, Shift+A/Shift+D). these commands lack the specialized, high-visibility OSD feedback that characterizes the Kardenwort suite's premium feel. Users want to configure the seek amount and see it clearly in the center of the screen to confirm the skip distance.

## Goals / Non-Goals

**Goals:**
- Provide large, centered OSD feedback (e.g., `+2`) for time-based seeks.
- Centralize seek amount configuration in `mpv.conf` via script options.
- Maintain layout symmetry across English and Russian keyboard configurations.

**Non-Goals:**
- Modifying subtitle-based seeking (handled by `lls-seek_prev/next`).
- Overhauling the entire OSD system (limit to seek feedback).

## Decisions

- **Decision 1: Shift to Script-Mediated Seeking**
  - **Rationale**: By wrapping native `seek` commands in script bindings (`lls-seek_time_forward/backward`), we can inject custom ASS-styled OSD messages that are independent of global mpv OSD levels.
  - **Alternative**: Listen to native seek properties. **Rejection**: Less precise control over the visual feedback timing and content.

- **Decision 2: Dead-Center ASS Alignment (`{\an5}`)**
  - **Rationale**: Center-center alignment is the most distinctive for critical behavioral feedback, creating a "HUD" experience that feels premium and intentional.
  - **Alternative**: Standard middle-left (`{\an4}`). **Rejection**: Less impact; current `show_osd` uses `{\an4}` for general messages, so `{\an5}` provides visual distinction for seeks.

- **Decision 3: Unified `seek_time_delta` Parameter**
  - **Rationale**: Users want a single "knob" to adjust their preferred skip distance.
  - **Alternative**: Multiple parameters for different keys. **Rejection**: Unnecessary complexity; most users prefer a consistent delta for all primary time-seek keys.

## Risks / Trade-offs

- **[Risk]** OSD overlapping with subtitles. → **Mitigation**: The centered message will be transient (2.0s default) and can be configured or disabled by the user via `seek_osd_duration`.
- **[Risk]** Input lag from script execution. → **Mitigation**: Lua `mp.commandv` calls are extremely fast; the overhead is negligible compared to the seek operation itself.
