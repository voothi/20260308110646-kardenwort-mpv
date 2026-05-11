## Context

The implementation currently mixes global and mode-local controls. In particular, the interactive binding activator treated normal SRT as interactivity-active, which let DW navigation/control bindings execute outside DW context.

## Mode Matrix

| Mode | Activation condition | Owned mutable state | Allowed interaction scope | Disallowed mutations |
|---|---|---|---|---|
| `srt` | `DRUM=OFF`, `DRUM_WINDOW=OFF` | playback/autopause/karaoke/global subtitle visibility | global playback controls only | DW cursor/anchor/selection state; DW copy/context toggles |
| `dm` | `DRUM=ON`, `DRUM_WINDOW=OFF` | drum render + OSD interactivity | drum selection/copy/tooltip interactions | DW window lifecycle and DW-only mode toggles |
| `dw` | `DRUM_WINDOW!=OFF` | DW cursor/anchor/view/select/copy/context + tooltip force/target | full DW keyboard+mouse system | unrelated base-mode toggles that would desync DW state |

## Transition Scheme

```text
srt --toggle-drum--> dm
dm  --toggle-drum--> srt
srt --toggle-drum-window--> dw
dm  --toggle-drum-window--> dw
dw  --toggle-drum-window--> srt (restoring saved visibility/drum context)
```

Policy: transitions may carry *read-only context* (active line/time), but cannot execute write actions owned by another mode unless explicitly transitioning into that mode.

## Decisions

1. Guard DW-only state writes at command level.
- `cmd_cycle_copy_mode`, `cmd_toggle_copy_ctx` require `dw`.

2. Restrict runtime interactivity activation.
- `update_interactive_bindings()` only enables OSD-driven DW binding set for `dm` and `dw`; plain `srt` is excluded.

3. Keep global playback behavior intact.
- Autopause/karaoke/replay/seek remain global and unchanged.

4. Key-ignore policy.
- Maintain a dedicated "encountered accidental keys" list in `input.conf`; additions must be accompanied by a short rationale comment and an acceptance check.

## Risks / Trade-offs

- Risk: users expecting SRT-phase keyboard interactivity may notice stricter behavior.
  - Mitigation: preserve DM/DW interaction parity and add explicit tests for intended scopes.

- Risk: over-guarding can block legitimate workflows.
  - Mitigation: only guard clearly DW-owned mutation commands in this change; expand incrementally.
