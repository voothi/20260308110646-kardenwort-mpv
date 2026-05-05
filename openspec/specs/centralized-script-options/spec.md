# Spec: Centralized Script Options

## Purpose
Decoupling configuration from code is essential for user-friendly customization.
## Requirements
- All adjustable parameters SHALL be moved from `lls_core.lua` to `mpv.conf`.
- The `script-opts-append` syntax SHALL be used for the `lls_core` identifier.
- Parameters SHALL include AutoPause thresholds, Drum Mode settings, Immersion Modes, and UI toggles.

### Requirement: Full Configuration Parity
100% of the `Options` table in `lls_core.lua` MUST be exposed in `mpv.conf` to prevent hidden state that cannot be adjusted by the user.

#### Scenario: Missing options in mpv.conf
- **WHEN** an option is added to the script's `Options` table
- **THEN** it must be added to `mpv.conf` with a corresponding comment if it involves user interaction.

## Verification
- Verify that changes made to `script-opts` in `mpv.conf` are reflected in script behavior.
- Confirm that `lls_core.lua` calls `mp.options.read_options`.
