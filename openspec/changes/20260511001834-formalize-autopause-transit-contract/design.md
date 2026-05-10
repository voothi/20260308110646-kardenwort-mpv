## Context

Recent iterations around Autopause ON + PHRASE rewind behavior repeatedly regressed because two legitimate behaviors were mixed in one path: strict phrase-end pausing and smooth cross-subtitle transit. The project now has a plain-language mechanism review and a single-action request interface, but these must be converted into enforceable OpenSpec requirements so implementation can be performed once with explicit scope limits.

## Goals / Non-Goals

**Goals:**
- Define deterministic split behavior for rewind/replay transit:
- inside-card movement preserves normal autopause end behavior,
- cross-card movement enters temporary smooth transit suppression.
- Formalize transit inhibit lifecycle (`set`, `gate`, `clear`, stale reset) so state cannot leak.
- Add a stable communication protocol capability to lock request intent before implementation.
- Keep implementation surgical in existing playback functions.

**Non-Goals:**
- Redesign of Drum Window UI/selection or tooltip systems.
- Global behavioral changes to MOVIE mode.
- Refactor of unrelated playback architecture.

## Decisions

1. Split-condition decision: classify navigation as inside-card vs cross-card at seek/replay trigger time and store transit intent in FSM.
- Alternative considered: timer-only suppression window.
- Rejected because delayed playback start can expire timer before actual transit.

2. Transit gating decision: suppress both autopause boundary checks and PHRASE jerk-back only while cross-card transit inhibit is active.
- Alternative considered: disable only autopause.
- Rejected because jerk-back alone can still cause perceived overlap replay.

3. Lifecycle hygiene decision: clear inhibit only on deterministic completion conditions and explicitly clear it on unrelated manual navigation entries.
- Alternative considered: clear in generic jump detector only.
- Rejected because edge timing can race with boundary checks.

4. Protocol decision: introduce `playback-change-interface` capability to require explicit Goal/Trigger/Expected/Must-Not-Change/Acceptance/Scope before edits.
- Alternative considered: rely on ad hoc chat summaries.
- Rejected due to repeated ambiguity and requirement drift.

## Risks / Trade-offs

- [Risk] Split detection misclassifies borderline seeks near subtitle boundaries.
  -> Mitigation: use active-card index comparison before/after seek target and verify with overlap-heavy fixture scenarios.

- [Risk] Over-suppression masks valid PHRASE pauses.
  -> Mitigation: enforce requirement that inside-card rewinds never enable cross-card suppression.

- [Risk] Stale inhibit survives into unrelated actions.
  -> Mitigation: explicit reset points in manual navigation handlers and strict completion clear condition.

- [Trade-off] Slightly higher FSM state complexity.
  -> Mitigation: constrain changes to existing transit paths and document all state fields in spec scenarios.
