## Context

The `populate_token_meta` function is the central engine for colorizing interactive tokens. Historically, it relied on a rigid set of global `dw_` options, which made it impossible to tune selection brightness independently for secondary tracks or specific viewing modes (SRT/Drum). As the project moves toward a "Unified interactivity and highlighting schema," we must decouple these visual markers from their hardcoded origins to support different display environments (e.g., contrasting primary vs. secondary track luminance).

## Goals / Non-Goals

**Goals:**
- Decouple selection highlighting from the global `dw_` namespace for all modes.
- Enable independent color calibration for Tooltip, Drum Mode (Pri/Sec), and SRT Mode (Pri/Sec).
- Preserve $O(1)$ rendering performance via efficient color parameter passing.

**Non-Goals:**
- Fragmenting the core logic (keeping a single source of truth for selection rules).
- Changing default aesthetic values (maintaining backward compatibility).

## Decisions

### 1. Parameterized Palette Injection
`populate_token_meta` is refactored to accept `h_color` and `ctrl_color` as arguments.
- **Rationale**: This shifts the responsibility of palette selection to the high-level rendering loops (`draw_dw_core`, `draw_dw_tooltip`, `draw_drum`), which already have context about the current mode and track.
- **Alternative**: Passing a "mode" string and having the service perform internal lookups was rejected as it would re-introduce coupling with the `Options` table structure.

### 2. Uniform Track Calibration
New options for `drum_pri/sec` and `srt_pri/sec` follow the same naming convention as existing track-specific toggles.
- **Rationale**: Ensures a predictable configuration surface for power users.

## Risks / Trade-offs

- **[Risk] Configuration Complexity** → **Mitigation**: New options default to legacy values in the `Options` table, so only users who need specific calibration need to modify `mpv.conf`.
- **[Trade-off] Redundant Arguments** → **Mitigation**: Using optional arguments with clear fallbacks ensures that existing logic (or future modes) can still function with standard project defaults.
