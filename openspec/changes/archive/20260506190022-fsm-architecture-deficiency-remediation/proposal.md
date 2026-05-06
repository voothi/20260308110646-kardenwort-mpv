## Why

The current implementation is close to the FSM architecture spec but still has contract gaps that can produce inconsistent runtime behavior and make future audits noisy. We need a targeted remediation change so code, behavior, and OpenSpec requirements are aligned again.

## What Changes

- Tighten ASS gatekeeping so FSM transitions are explicit and symmetrical when ASS media contexts are detected.
- Define and enforce full lifecycle symmetry for search-mode forced character bindings, including German characters.
- Clarify and align the Drum Window Esc stage contract with implemented behavior so documentation and runtime expectations match.
- Add acceptance-focused regression checks for these FSM invariants to prevent drift after future refactors.

## Capabilities

### New Capabilities
- `fsm-regression-acceptance`: Lightweight verification scenarios for high-risk FSM invariants around mode transitions and modal input lifecycle.

### Modified Capabilities
- `fsm-architecture`: Refine requirements for ASS compatibility gatekeeping, search binding lifecycle integrity, and Esc-stage interaction contract.

## Impact

- Affected code: `scripts/lls_core.lua` (FSM transition handlers, search binding setup/teardown, Esc flow).
- Affected specifications: `openspec/specs/fsm-architecture/spec.md` and corresponding delta spec under this change.
- Runtime impact: lower risk of stale input captures, clearer mode-transition safety under ASS, and consistent user-visible behavior under Esc.
