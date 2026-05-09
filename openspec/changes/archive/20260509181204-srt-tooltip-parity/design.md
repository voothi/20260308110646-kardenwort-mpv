## Context

Currently, the tooltip system (used for translations and dictionary lookups) is explicitly restricted to `FSM.DRUM == "ON"` or `FSM.DRUM_WINDOW ~= "OFF"`. This prevents users who use the "Regular" SRT mode with custom OSD styling from accessing tooltips, even though the underlying hit-zone and rendering logic is already compatible with SRT OSD.

## Goals / Non-Goals

**Goals:**
- Enable tooltips in SRT mode when custom OSD rendering is active.
- Maintain consistency between Drum Mode and SRT mode interactions.
- Rename internal functions to reflect the broader scope.

**Non-Goals:**
- Supporting tooltips for native ASS subtitles (where hit zones are not calculated).
- Modifying the tooltip rendering itself; the focus is on activation logic.

## Decisions

### 1. Rename `is_drum_tooltip_mode_eligible` to `is_osd_tooltip_mode_eligible`
The existing name implies a restriction to Drum Mode that we are removing. Renaming clarifies the function's purpose: checking if the current OSD state supports tooltips.

### 2. Update Eligibility Logic
The new logic will allow tooltips if:
- Drum Window is OFF.
- Native subtitles are visible (meaning we are rendering something).
- Not an ASS subtitle (matches current restriction).
- `osd_interactivity` is enabled.
- **EITHER** Drum Mode is ON **OR** the current SRT subtitle is being rendered via custom OSD (determined by `use_osd_for_srt` logic).

### 3. Verification of Hit-Zone Data
The `tick_drum` function (which handles both Drum and SRT OSD) already populates `FSM.DRUM_HIT_ZONES` correctly. No changes to the rendering pipeline or hit-test logic are required beyond the eligibility gate.

## Risks / Trade-offs

- **Interaction Overlap**: In SRT mode, tooltips might overlap with other OSD elements if not carefully positioned. However, since SRT OSD usually occupies the same space as Drum Mode, the existing `get_tooltip_line_y` logic should hold.
