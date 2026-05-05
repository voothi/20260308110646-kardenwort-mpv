## Context

The `lls_core.lua` script uses an `Options` table to manage user-configurable parameters and a `FSM` (Finite State Machine) table for runtime state. Currently, `IMMERSION_MODE` is initialized to a static string "PHRASE" in the `FSM` table, bypassing the `Options` system.

## Goals / Non-Goals

**Goals:**
- Expose the startup Immersion Mode as a configurable parameter.
- Ensure the parameter is compatible with the existing `mp.options` loading mechanism.
- Maintain consistency across documentation (`README.md`) and default configuration (`mpv.conf`).

**Non-Goals:**
- Modifying the logic of `MOVIE` or `PHRASE` modes themselves.
- Adding complex multi-mode startup profiles (e.g., per-file mode overrides).

## Decisions

- **Parameter Name**: `immersion_mode_default` will be added to the `Options` table.
- **Initialization Timing**: `FSM.IMMERSION_MODE` will be initialized using a ternary check against `Options.immersion_mode_default` after `options.read_options` has completed.
- **Validation**: The initialization will default to `PHRASE` if an invalid value is provided in the configuration.

## Risks / Trade-offs

- **Redundancy**: Adding another option to the already large `Options` table (150+ parameters). However, this is necessary for full configuration parity as per existing requirements.
