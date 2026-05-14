## Context

Between `v1.80.18` and the follow-up patch chain, the same user-visible bug was addressed through multiple competing mechanisms: live `time-pos` re-anchor, cached index re-anchor, repeat time guards, and a local pointer FSM. The sequence fixed individual edges but introduced new ones (double-step repeats, blinking/middle skip, Lua scope crash, and unresolved desync).

The common issue is architectural: pointer activation consumes navigation intent from mixed timing domains (tick-updated state vs key-event stream) without a single authoritative snapshot per intent. Structural tests passed because they validated source patterns, but they did not validate boundary-time runtime behavior.

## Goals / Non-Goals

**Goals:**
- Define one deterministic pointer-activation intent model for DW/DM.
- Ensure null-pointer activation binds to a single resolved context snapshot per key intent.
- Make event handling explicit (`down`, `repeat`, `up`) and state-aware without timing magic constants.
- Add runtime acceptance coverage for boundary activation behavior.

**Non-Goals:**
- No rewrite of subtitle indexing engine or rendering layout pipeline.
- No change to Esc staged semantics (pink -> range -> pointer) beyond clarified activation contract.
- No redesign of Book Mode paging behavior.

## Decisions

### Decision 1: Introduce a single Navigation Intent Snapshot contract
We will resolve an `intent_context` exactly once for each navigation intent entry point and pass it through line/word movement logic.

Why:
- Removes race between per-tick `DW_ACTIVE_LINE` refresh and ad-hoc event-time recomputation.
- Prevents handlers from reading different active sources inside one physical key gesture.

Alternatives considered:
- Keep live `time-pos` reads directly in handlers: precise but unstable under repeat sequences.
- Keep only cached `DW_ACTIVE_LINE`/`ACTIVE_IDX`: stable but late at boundary ticks.

Chosen compromise:
- Snapshot resolver with explicit fallback order and validity checks, then immutable use during one intent.

### Decision 2: Formalize key-event gating by pointer state, not by timers
Arrow handlers will consume events based on pointer state and event type:
- `up` ignored for movement.
- In null activation state, exactly one activation move per physical intent entry.
- `repeat` behavior allowed only after pointer is active manual and no null-activation lock is pending.

Why:
- Eliminates fragile `+0.12s` timing windows.
- Matches observed failure mode where auto-repeat bleeds into activation.

Alternatives considered:
- Continue time-based guard: easy patch, repeatedly regressed.
- Global input throttling: too broad, risks collateral behavior changes.

### Decision 3: Add deterministic desync-rebase rule before movement continuation
If pointer is manual-active on a non-active line during live playback and user navigates without Shift, the pointer source rebases to current active index before continuing the same intent.

Why:
- Encodes the empirically working recovery (`UP -> Esc -> UP`) into one deterministic path.
- Keeps manual range workflows intact by excluding Shift/range-active transitions.

Alternatives considered:
- Force Esc-like reset before all movement: too disruptive.
- Never rebase manual pointer: preserves stale state and reproduces bug.

### Decision 4: Promote runtime boundary tests to required regression gates
Acceptance must include runtime scenarios that operate around subtitle boundary timing and event sequences, not only structural string assertions.

Why:
- Previous chain passed structural tests while failing in real playback.

## Risks / Trade-offs

- [Risk] Added state complexity for navigation-intent lifecycle.
  - Mitigation: keep state machine minimal and localized; document transitions in spec and tests.
- [Risk] Event model differences across keyboard layouts/platform bindings.
  - Mitigation: validate EN/RU arrow bindings through shared event contract and runtime tests.
- [Risk] Over-correction may alter expected manual navigation feel.
  - Mitigation: explicitly constrain changes to null activation and desync-rebase edges; preserve normal active-pointer stepping.

## Migration Plan

1. Implement intent snapshot resolver and event-gating plumbing in navigation handlers and bindings.
2. Add/adjust runtime acceptance tests for boundary-time activation and repeat semantics.
3. Run targeted acceptance suite for DM/DW state edges, then full regression suite.
4. Release behind normal branch flow; rollback by reverting this change set if behavior diverges.

## Open Questions

- Should boundary-runtime tests use a deterministic synthetic subtitle fixture specifically crafted for near-start key events?
- Should we expose optional debug telemetry for intent snapshots (disabled by default) to simplify future field diagnosis?
