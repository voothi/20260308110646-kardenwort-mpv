## Why

Pointer activation around subtitle boundaries (especially AUTOPAUSE OFF, MOVIE mode) remains nondeterministic after multiple patch iterations after `v1.80.18`. The regressions show a systemic race between playback-index refresh, Esc stage transitions, and arrow key event sequencing, so we need a single source-of-truth activation model instead of additional local guards.

## What Changes

- Introduce a dedicated navigation-intent contract for DW/DM pointer activation with one resolved context snapshot per key intent.
- Normalize arrow event handling (`down/repeat/up`) so null-pointer activation consumes exactly one intended step and does not depend on timing windows.
- Define deterministic rebase behavior when manual yellow pointer state is desynchronized from currently playing white subtitle state.
- Add runtime acceptance coverage for boundary-tick activation scenarios (not only structural source-string checks).
- Align state traceability and regression checklist requirements with the new intent model.

## Capabilities

### New Capabilities

- `dw-pointer-intent-synchronization`: Canonical intent snapshot and event-gating model for DW/DM pointer activation under live playback.

### Modified Capabilities

- `drum-window-navigation`: Tighten null-pointer activation, event sequencing, and desync-rebase requirements for UP/DOWN/LEFT/RIGHT.
- `dm-dw-state-traceability`: Extend traceability and checklist requirements with explicit boundary-runtime validation for pointer activation accuracy.

## Impact

- Affected code: `scripts/kardenwort/main.lua` (pointer activation path, key-binding event plumbing, follow/anchor transition points).
- Affected tests: `tests/acceptance/test_20260514001942_dm_dw_state_edges.py` plus new runtime acceptance cases for boundary-event behavior.
- Affected specs: `openspec/specs/drum-window-navigation/spec.md`, `openspec/specs/dm-dw-state-traceability/spec.md`, and new `openspec/specs/dw-pointer-intent-synchronization/spec.md`.
