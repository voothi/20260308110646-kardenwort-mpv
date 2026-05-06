# Proposal: Drum Scroll Synchronization Hardening

## Why
The archived change `20260506103358-unify-drum-mode-wheel-scroll` improved behavior, but a review against code and FSM expectations reveals remaining mismatches:
- Scroll behavior and docs diverge when wheel input occurs outside subtitle hit zones.
- Secondary-track viewport coupling is underspecified in edge cases.
- Autopause guarantees (`ON/OFF`, `PHRASE/MOVIE`) are not explicitly protected from drum viewport scrolling logic.

## What Changes
1. Define strict dual-track viewport synchronization semantics for manual drum scrolling.
2. Define strict highlight synchronization semantics between lower/upper subtitle lanes during manual scroll.
3. Specify wheel-event routing policy outside hit zones so implementation and docs match.
4. Add explicit FSM safety constraints so drum viewport scrolling cannot mutate autopause state transitions.
5. Add a regression matrix requirement against reference commit `4c634ed422844c475293dac07bad7d149e9f9df8`.

## Scope
- OpenSpec artifacts only (proposal/design/tasks/spec requirements).
- No runtime code changes in this change.

## Impact
- Reduces ambiguity before the next implementation pass.
- Prevents repeated regressions from conflicting model interpretations.
