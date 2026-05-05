## Context

The Kardenwort-mpv immersion engine manages complex UI states including a dedicated Drum Window, multiple selection types (Yellow/Pink), and varied playback modes. Previously, the OSD feedback for these states was inconsistent, and interactions with the `Esc` key were prone to "over-resetting," where the entire window would close when the user only intended to clear a sub-selection. Additionally, subtitle positioning keys (`r`, `t`) were not properly guarded during immersion, leading to accidental visual shifts.

## Goals / Non-Goals

**Goals:**
- Implement a "Descriptive Minimalist" OSD system that provides clear labeling (prefixes) without technical noise.
- Decouple "Clear Selection" from "Close Window" in the `Esc` interaction to prevent cyclic mode switching.
- Harden immersion state by intercepting and silently blocking positioning keys during active sessions.
- Provide context-aware feedback for clipboard actions (Regular vs. Drum Window).

**Non-Goals:**
- Modifying the underlying rendering engine (OSC/ASS) beyond OSD text changes.
- Changing the fundamental behavior of the Drum Mode state machine logic itself.

## Decisions

### 1. Forced Key Bindings for Immersion Hardening
**Rationale**: Native `mpv` keybindings often provide their own OSD feedback. By using `mp.add_forced_key_binding` for positioning keys (`r`, `t`, `R`, `T`), the script gains absolute priority. This allows the engine to silently block these keys during immersion modes, preventing the native "Subtitle position: X%" noise and accidental shifts.

### 2. Staged Reset Architecture for `Esc`
**Rationale**: To prevent cyclic toggling of the Drum Window, the `cmd_dw_esc` function was refactored into sequential stages:
- **Stage 1**: Clear Pending Sets (Pink/Purple).
- **Stage 2**: Clear Yellow Ranges (multi-word).
- **Stage 3**: Full Reset via `dw_reset_selection` (Yellow pointer + cursor sync).
**Note**: Stage 4 (Close Window) was explicitly removed to ensure the user stays in the window until they press the dedicated toggle (`w`).

### 3. Dynamic Prefix Formatting
**Rationale**: OSD messages now follow a `[Prefix]: [Status]` pattern. Labels like `DW Copied` are dynamically determined based on the `FSM.DRUM_WINDOW` state, ensuring the user understands the source of the data without redundant headers.

### 4. Label Optimization
**Rationale**: Long prefixes like `Secondary Subtitles:` were shortened to `Secondary Sub:` to minimize screen real estate usage while maintaining clarity.

## Risks / Trade-offs

- **[Risk]** Forced bindings might override user-specific global hotkeys. -> **[Mitigation]** The bindings are only "forced" within the context of the script's registration, and the script provides options to remap these keys in `mpv.conf`.
- **[Trade-off]** Silent blocking provides no feedback that a key is pressed. -> **[Decision]** This is intentional to reduce "noise" during high-focus immersion sessions.
