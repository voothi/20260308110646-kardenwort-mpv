## Context

The current tooltip workflow is mature in Drum Window (W) but not available with equivalent reliability in Drum Mode (C) on the bottom primary subtitle surface. Users need Drum Mode to behave as a compact “mini z-reel” interaction mode so tooltip access does not require mode switching.

Recent FSM hardening introduced strict ownership boundaries between `DRUM`, `DRUM_WINDOW`, native subtitles, and modal input paths. Any tooltip migration must preserve these transition guarantees and avoid regressions in visibility suppression, ASS gatekeeping, and Esc-stage behavior.

## Goals / Non-Goals

**Goals:**
- Enable tooltip activation in Drum Mode for primary subtitle hit-zones using the coordinated key model.
- Keep key-layout parity (same logical action for configured multi-key lists, including alternate layouts).
- Preserve deterministic FSM ownership so Drum Mode tooltip and Drum Window tooltip do not fight for overlay control.
- Reuse existing tooltip lifecycle safety (draw, invalidate, clear) for predictable behavior.

**Non-Goals:**
- No Book Mode migration or behavioral changes.
- No redesign of Anki export, copy-mode semantics, or selection-stage Esc ordering.
- No visual restyling overhaul outside what is required for Drum Mode tooltip visibility.

## Decisions

1. Shared Tooltip Intent, Mode-Specific Execution
- Decision: keep one logical tooltip intent (toggle/hover/pin semantics) but route execution by active mode (`DRUM_WINDOW` vs `DRUM`).
- Rationale: preserves user mental model and existing key configuration while preventing cross-mode side effects.
- Alternative considered: duplicate Drum-specific tooltip key options. Rejected due to config drift and higher maintenance.

2. Explicit FSM Overlay Ownership Gate
- Decision: add an explicit gate that allows tooltip rendering in Drum Mode only when `FSM.DRUM == "ON"`, `FSM.DRUM_WINDOW == "OFF"`, and subtitle visibility is effectively enabled.
- Rationale: aligns with mutual exclusion guarantees and prevents hidden/off-mode tooltip ghosts.
- Alternative considered: opportunistic rendering whenever hit-zones exist. Rejected due to stale-state risk.

3. Reuse Existing Hit-Zone Lifecycle Contract
- Decision: extend the tooltip hit-zone lifecycle contract to Drum Mode rather than inventing a second lifecycle.
- Rationale: a single invalidation model reduces drift and keeps behavior testable.
- Alternative considered: separate Drum-only lifecycle tables. Rejected due to duplicate invalidation logic.

4. Mini z-reel Contract Without Book Mode
- Decision: define a focused capability for Drum Mode tooltip-as-mini-z behavior while explicitly excluding Book Mode.
- Rationale: meets requested workflow quickly and safely, limits blast radius.

## Risks / Trade-offs

- [Risk] Key-binding precedence collisions between Drum Mode tooltip keys and existing Drum navigation keys.
  - Mitigation: apply mode-aware binding ownership and deterministic unbind/rebind ordering during mode transitions.

- [Risk] Tooltip state leakage when switching rapidly between Drum Mode and Drum Window.
  - Mitigation: central clear/invalidate hook on every DRUM/DRUM_WINDOW transition edge.

- [Risk] ASS gatekeeping may unexpectedly suppress tooltip availability.
  - Mitigation: keep tooltip eligibility dependent on the same media-context gate used for Drum rendering and expose clear OSD diagnostics.

## Migration Plan

1. Add spec deltas and capability contract for Drum mini z tooltip behavior.
2. Implement mode-routed key dispatch and shared tooltip intent handlers in `lls_core.lua`.
3. Extend hit-zone generation and tooltip draw path for Drum Mode primary subtitle surface.
4. Add transition-edge cleanup hooks and regression checks for mode switching.
5. Validate against FSM scenarios (Drum ON/OFF, DW ON/OFF, ASS context, subtitle visibility toggles).

## Open Questions

- Should Drum Mode tooltip prioritize hover-only activation when playback is running, and require toggle/pin when paused?
- Should Drum Mode tooltip inherit exactly the same timing thresholds as DW, or allow a dedicated scalar later via config?
