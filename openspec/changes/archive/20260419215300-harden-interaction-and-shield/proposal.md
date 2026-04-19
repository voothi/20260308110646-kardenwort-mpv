# Proposal: Interaction Shield & Jitter Resilience

## Problem
When using the Drum Window via remote control software (e.g., JoyToKey or 8BitDo native mapping), input jitter or misconfigured "combo" mappings can cause simultaneous keyboard and mouse signals (e.g., `t` + `MBTN_LEFT`). This results in the yellow focus cursor "jumping" to the mouse pointer position just before the keyboard command executes, breaking the remote-only interaction model.

## Solution
Implement a **Mouse Interaction Shield**.
- Detect all keyboard/remote triggers in the Drum Window.
- Upon any keyboard trigger, activate a 150ms "mouse lock" in the global state.
- Block all incoming mouse handler events (from `make_mouse_handler`) while the lock is active.
- This ensures keyboard commands always have priority and are isolated from hardware-level mouse noise.

## Impact
- **Stability**: Eliminates focus jumps for remote control users.
- **Resilience**: Script remains fully functional even with sub-optimal input mapper software.
- **Precision**: Maintains perfect viewport-pointer separation.
