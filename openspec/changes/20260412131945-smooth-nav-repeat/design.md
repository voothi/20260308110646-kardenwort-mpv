# Design: Unified Smooth Subtitle Navigation

## Context
The current navigation system in `lls_core.lua` relies on a mix of native mpv key-repeat (in Window mode) and no repeat (in other modes). This leads to an inconsistent user experience where holding down 'a' or 'd' works differently (or not at all) depending on the active mode. The user has requested a stable, configurable auto-scrolling mechanism that feels premium and is consistent across all modes.

## Goals / Non-Goals

**Goals:**
- Provide a unified auto-repeat mechanism for subtitle seeking (`a`/`d`, `ф`/`в`).
- Make the repeat parameters (delay and rate) user-configurable via `script-opts`.
- Ensure the mechanism is mode-agnostic, working identically in Normal mode, Drum mode, and Drum Window mode.
- Use an internal timer for high-precision event handling and "sticky-free" key releases.

**Non-Goals:**
- Replacing repeat for non-navigation keys (e.g., volume, speed).
- Implementing multi-key combos (other than existing ones like Ctrl/Shift which are handled by the same functions).

## Decisions

### 1. Script-Controlled Timers vs. Native Repeat
We will disable native `repeatable` flags for navigation keys and implement a custom state machine.
- **Rationale**: Native repeat is OS-dependent and does not support separate delay/rate settings per application easily. Script-controlled timers allow us to provide a sub-tick precision (using `mp.add_timeout` and `mp.add_periodic_timer`) and a consistent feel across Windows, Linux, and macOS.

### 2. Complex Bindings for Global Navigation
Global seek bindings (`lls-seek_prev/next`) will be converted to `{complex=true}`.
- **Rationale**: To support high-quality repeat, the script must know exactly when a key is released. Complex bindings allow the script to differentiate between `down`, `up`, and `press` events.

### 3. Unified State variable `FSM.SEEK_REPEAT_TIMER`
A single timer reference will be added to the Finite State Machine (FSM).
- **Rationale**: This prevents race conditions where multiple timers might be active simultaneously if the user rapidly masks keys. Only one navigation repeat can be active at a time.

### 4. Mode Integration via `cmd_seek_with_repeat` wrapper
All navigation bindings (global and mode-specific) will call a unified wrapper.
- **Rationale**: Centralizing the logic ensures that any bug fixes or future improvements to the "scrolling feel" automatically propagate to all modes.

## Risks / Trade-offs

- **Timer Resource**: Creating/killing timers on every keypress has negligible CPU impact but must be handled cleanly to avoid "dangling" timers if the script reloads or a mode changes unexpectedly.
- **Input Conflict**: If another script or global mpv binding also uses complex bindings for the same keys, there might be a conflict. However, since this script uses `add_forced_key_binding` for modes, it retains control.
