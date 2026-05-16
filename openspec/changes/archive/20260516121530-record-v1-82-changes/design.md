## Context

The current subtitle visibility system was binary (ON/OFF). With the introduction of secondary tracks for translations, users need more granular control to focus on one track at a time while maintaining state-machine (FSM) synchronization (e.g., auto-pause, mining). The Drum Window also required better error handling to avoid "zombie" UI states during crashes and more reliable line resolution for null activations.

## Goals / Non-Goals

**Goals:**
- Implement a three-state visibility cycle: Primary Only, Both, Secondary Only.
- Ensure "Secondary Only" mode still processes primary track events for FSM logic (seeking, auto-pause).
- Harden DW activation logic to prefer stable player-synced lines over lookahead-derived context.
- Implement atomic toggle for DW with error recovery via `xpcall`.

**Non-Goals:**
- Adding support for more than two simultaneous subtitle tracks.
- Modifying the underlying `libass` rendering engine or native mpv property behavior beyond our overrides.

## Decisions

- **FSM-Driven Visibility**: Introduced `FSM.SEC_ONLY_MODE` as a high-level state. The `master_tick` loop uses this flag to decide which tracks to render to the OSD, while keeping both tracks "active" in the FSM to ensure features like auto-pause continue to work.
- **Stable Line Priority**: In `dw_resolve_null_activation_line`, we now prioritize `FSM.DW_ACTIVE_LINE` because it represents the most recent player-synchronized state. Lookahead context is used as a fallback only when no stable line is available.
- **Atomic UI Toggling**: Wrapped `cmd_toggle_drum_window` in `xpcall`. This ensures that if a Lua error occurs during the complex initialization (loading TSV, snapshotting visibility), the FSM state is rolled back to its previous value, preventing the UI from being stuck in a "DOCKED" state without actually being visible.

## Risks / Trade-offs

- **Risk: Interaction between SEC_ONLY_MODE and native visibility** → Mitigation: `master_tick` explicitly enforces visibility states every cycle to prevent native mpv logic from overriding our filtered display.
- **Risk: Snapshot lookahead jitter** → Mitigation: Priority-based resolution in `dw_resolve_null_activation_line` ensures we only use lookahead when the player is truly in a "gap" or undefined state.
