## Why

Autopause ON in PHRASE mode currently has recurring regressions around manual rewind transit (`Shift+a/d`, `s` replay): fixes that smooth cross-subtitle handover often break normal phrase-end stopping, and vice versa. We need one explicit behavioral contract and one request protocol so the next implementation is done once, minimally, without collateral regressions.

## What Changes

- Formalize a split transit contract for Autopause ON + PHRASE:
- Inside-card rewind keeps normal autopause stopping at subtitle end.
- Cross-card rewind uses temporary MOVIE-like transit (suppress overlap pause and PHRASE jerk-back) until transit completion.
- Define strict inhibit lifecycle rules (`set`, `suppress`, `clear`, stale-state cleanup) for rewind transit.
- Add a human-facing, non-programmer communication interface template for future one-action fixes (goal/trigger/expected/must-not-change/acceptance/scope).
- Align implementation scope boundaries so only transit gating paths are touched; no behavior drift in ordinary PHRASE forward playback.

## Capabilities

### New Capabilities
- `playback-change-interface`: A standardized single-action change request protocol for playback behavior fixes, including explicit acceptance and non-regression boundaries.

### Modified Capabilities
- `immersion-engine`: Clarify and harden PHRASE-vs-transit behavior for manual rewind and replay crossings.
- `karaoke-autopause`: Refine autopause suppression semantics to apply only to cross-card transit, not inside-card rewinds.
- `fsm-architecture`: Define deterministic transit inhibit lifecycle and guard interaction with jerk-back / natural progression paths.

## Impact

- Affected code: `scripts/lls_core.lua` (`cmd_seek_time`, `tick_autopause`, `master_tick`, transit inhibit hygiene points).
- Affected specs: immersion, autopause, FSM requirements; plus a new protocol capability spec.
- Affected docs/workflow: adds an operator-facing request interface used before implementation.
- No expected impact on drum window rendering, tooltip behavior, or non-playback UI paths.
