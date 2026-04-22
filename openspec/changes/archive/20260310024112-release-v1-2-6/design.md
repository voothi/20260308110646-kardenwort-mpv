## Context

The audit of `scripts/lls_core.lua` identified a single hardcoded keybinding (`"c"`) that bypassed the intended `input.conf` authority. Additionally, the repository contained `old_copy_sub.lua`, a legacy script whose logic had already been absorbed into the FSM core.

## Goals / Non-Goals

**Goals:**
- Eliminate all hardcoded keybindings from script logic.
- Remove obsolete source files.
- Modernize `.gitignore`.

## Decisions

- **Key Deferment**: In `lls_core.lua`, the `mp.add_key_binding` call for `toggle-drum-mode` is updated from `"c"` to `nil`. This requires `input.conf` to contain `c script-binding toggle-drum-mode` for the feature to remain active.
- **Legacy Removal**: `scripts/old_copy_sub.lua` is removed from tracking to prevent confusion with the modern `lls_core.lua` implementation.
- **Git Hygiene**: `__pycache__/` is added to `.gitignore` to support clean Python-based tools and simulations used during development.

## Risks / Trade-offs

- **Risk**: Breaking the feature for users without a proper `input.conf`.
- **Mitigation**: The documentation and default configuration must ensure the binding is present in `input.conf`.
