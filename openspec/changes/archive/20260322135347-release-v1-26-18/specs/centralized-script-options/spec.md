# Spec: Centralized Script Options

## Context
Decoupling configuration from code is essential for user-friendly customization.

## Requirements
- Move all adjustable parameters from `lls_core.lua` to `mpv.conf`.
- Use the `script-opts-append` syntax for the `lls_core` identifier.
- Parameters must include AutoPause thresholds, Drum Mode settings, and UI toggles.

## Verification
- Verify that changes made to `script-opts` in `mpv.conf` are reflected in script behavior.
- Confirm that `lls_core.lua` calls `mp.options.read_options`.
