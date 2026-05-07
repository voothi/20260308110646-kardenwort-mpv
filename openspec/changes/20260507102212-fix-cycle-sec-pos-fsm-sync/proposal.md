## Why

`cmd_cycle_sec_pos` writes the new secondary subtitle position to the mpv property in its non-Drum branch but never updates `FSM.native_sec_sub_pos`, leaving the FSM desired-state stale. The Drum branch already syncs both. This gap was not caught by the `20260507090243` remediation, which fixed the same class of desync in `cmd_adjust_sec_sub_pos`.

## What Changes

- In `cmd_cycle_sec_pos` (non-Drum branch, `scripts/lls_core.lua` ~line 7449), add `FSM.native_sec_sub_pos = n` after `mp.set_property_number("secondary-sub-pos", n)`.
- Add an explicit scenario to `fsm-architecture` spec covering `cmd_cycle_sec_pos` toggle sync, making the requirement unambiguous for both write paths.

## Capabilities

### New Capabilities

_(none)_

### Modified Capabilities

- `fsm-architecture`: Add scenario documenting that `cmd_cycle_sec_pos` must sync `FSM.native_sec_sub_pos` in all branches (not limited to the `cmd_adjust_sec_sub_pos` delta path already specified).

## Impact

- `scripts/lls_core.lua`: one-line addition in `cmd_cycle_sec_pos` else-branch.
- `openspec/specs/fsm-architecture/spec.md`: new scenario under the "Secondary Position Bounds via Configuration" requirement.
- Zero visual impact; no new Options keys, no new FSM fields, no rendering changes.
