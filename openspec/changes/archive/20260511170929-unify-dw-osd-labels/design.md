## Context

The Drum Window (DW) mode currently manages several global keybindings but does so inconsistently. For instance, the `x` key (toggle drum) explicitly checks for `FSM.DRUM_WINDOW` and displays "X", while other keys like `Shift+x`, `c`, `Shift+c`, and `Shift+f` either do not provide this feedback or are not yet properly intercepted in a unified manner. Additionally, the positioning adjustment feedback in DW mode is considered too verbose ("Position Locked").

## Goals / Non-Goals

**Goals:**
- Unify OSD feedback for keys that are managed by the Drum Window.
- Simplify the "Position Locked" OSD message to "X" for total consistency.
- Ensure consistent UI behavior when attempting to use global shortcuts that are irrelevant or suppressed while the Drum Window is active.

**Non-Goals:**
- Changing the actual functionality of the keys (they already should be "managed" or suppressed, we are just improving the feedback).
- Modifying the styling of the OSD beyond the text content.

## Decisions

1. **Unify "Managed by" Feedback**: Add `if FSM.DRUM_WINDOW ~= "OFF" then show_osd("X") return end` to:
   - `cmd_toggle_sub_vis` (c)
   - `cmd_cycle_sec_sid` (Shift+c)
   - `cmd_cycle_sec_pos` (Shift+x)
   - `cmd_toggle_karaoke` (Shift+f)
   
2. **Rename Status Label**: Update `cmd_adjust_sub_pos` and `cmd_adjust_sec_sub_pos` to show "X" instead of "Drum Window: Active (Position Locked)".

3. **Check for Redundancy**: `cmd_toggle_drum` already has the check, so it remains as is for consistency.

## Risks / Trade-offs

- **OSD Spam**: Users might find the "X" message annoying if they repeatedly press keys, but this is consistent with existing `x` key behavior and serves as a clear indicator of WHY a key isn't doing its default action.
