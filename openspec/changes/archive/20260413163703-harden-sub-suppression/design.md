## Context

The Kardenwort-mpv configuration uses custom OSD overlays (`ass-events`) for styled subtitle rendering (OSD-SRT, Drum Mode, and Drum Window). To prevent visual overlap, the native mpv `sub-visibility` and `secondary-sub-visibility` properties must be suppressed (set to `false`) whenever these custom renderers are active.

Currently, this suppression is managed in `master_tick` but is gated by an `FSM.DRUM_WINDOW == "OFF"` check. This creates a gap where platform events (like track cycling) can reactivate native subtitles while the Drum Window is open.

## Goals / Non-Goals

**Goals:**
- Ensure native subtitles are consistently suppressed while the Drum Window is active.
- Prevent "visibility leaks" during track changes and media state updates.
- Maintain the ability to restore native subtitles when all custom modes are closed.

**Non-Goals:**
- Changing the underlying OSD rendering logic for the Drum Window itself.
- Modifying how subtitles are parsed or loaded.

## Decisions

- **Unified Tick Suppression**: Refactor the native subtitle management block in `master_tick` to handle three primary states:
  1. **Drum Window Active**: Force `sub-visibility` to `false`.
  2. **Drum Mode / OSD-SRT Active**: Force `sub-visibility` to `false` and render the appropriate OSD content.
  3. **No OSD Active**: Restore `sub-visibility` based on `FSM.native_sub_vis`.

- **Updated FSM Guard**: Modify the top-level conditional in `master_tick` to include `FSM.DRUM_WINDOW ~= "OFF"` in the suppression criteria.

- **Track Change Hardening**: Ensure `update_media_state` doesn't inadvertently restore visibility if the Drum Window is open, even if it auto-disables standard Drum Mode.

## Risks / Trade-offs

- **Aggressive Suppression**: If a user tries to force-enable native subtitles via `mpv` commands (outside our `native_sub_vis` abstraction) while the window is open, they will be fought by the periodic timer. This is intended behavior to preserve UI integrity.
