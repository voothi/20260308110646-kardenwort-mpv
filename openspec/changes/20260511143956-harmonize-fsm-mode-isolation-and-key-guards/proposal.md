## Why

Mode interactions currently leak across contexts: while using SRT mode, DW-oriented keyboard handlers can still mutate copy/context state; while using DM/DW, shared commands can alter unrelated states. This creates "blind" setting changes and unpredictable behavior.

## What Changes

- Define a normalized mode matrix for `srt`, `dm`, `dw` with explicit state ownership, allowed actions, and blocked actions.
- Introduce mode guards for DW-only mutations (`copy_mode`, `copy_context`) so these actions cannot run outside `dw`.
- Tighten runtime input activation so DW keyboard/mouse bindings are only active in `dw` and `dm`, not plain `srt`.
- Add a tracked ignore-key policy for accidental/default mpv keys encountered during usage.
- Document transition rules and non-regression boundaries for mode switching.

## Capabilities

### Modified Capabilities
- `fsm-architecture`: Harmonize main-mode boundaries (`srt`/`dm`/`dw`) and prevent cross-mode state mutation.
- `coordinated-input-system`: Align keybinding activation and key-ignore coverage with mode ownership.

## Impact

- Affected code: `scripts/lls_core.lua`, `input.conf`
- Affected specs: `fsm-architecture`, `coordinated-input-system`
- Affected tests: acceptance tests around mode toggles and keyboard interactions
