## Context

The current seeking system uses native mpv `seek` commands for time-based navigation (LEFT/RIGHT, Shift+A/Shift+D). these commands lack the specialized, high-visibility OSD feedback that characterizes the Kardenwort suite's premium feel. Users want to configure the seek amount and see it clearly in the center of the screen to confirm the skip distance.

## Goals / Non-Goals

**Goals:**
- Provide large, directional OSD feedback (Left for backward, Right for forward) for time-based seeks.
- Implement dedicated styling parameters for seek OSD in `mpv.conf` (matching other mode schemas).
- Maintain layout symmetry across English and Russian keyboard configurations.

**Non-Goals:**
- Modifying subtitle-based seeking (handled by `lls-seek_prev/next`).
- Overhauling the entire OSD system (limit to seek feedback).

## Decisions

- **Decision 1: Shift to Script-Mediated Seeking**
  - **Rationale**: By wrapping native `seek` commands in script bindings (`lls-seek_time_forward/backward`), we can inject custom ASS-styled OSD messages that are independent of global mpv OSD levels.
  - **Alternative**: Listen to native seek properties. **Rejection**: Less precise control over the visual feedback timing and content.

- **Decision 2: Directional ASS Alignment (`{\an4}` / `{\an6}`)**
  - **Rationale**: Using the left-middle (`{\an4}`) for backward seeks and right-middle (`{\an6}`) for forward seeks provides intuitive spatial reinforcement of the navigation direction.
  - **Alternative**: Dead-center (`{\an5}`). **Rejection**: Directional positioning is more informative and visually dynamic.

- **Decision 3: Dedicated Style Schema for Seeks**
  - **Rationale**: Providing `seek_font_size`, `seek_color`, etc., ensures the seek OSD can be styled independently of general OSD or other mode-specific text (SRT/Drum), satisfying the requirement for granular control.
  - **Alternative**: Use general OSD styling. **Rejection**: Limits user customization.

## Risks / Trade-offs

- **[Risk]** OSD overlapping with subtitles. → **Mitigation**: The centered message will be transient (2.0s default) and can be configured or disabled by the user via `seek_osd_duration`.
- **[Risk]** Input lag from script execution. → **Mitigation**: Lua `mp.commandv` calls are extremely fast; the overhead is negligible compared to the seek operation itself.
