# Spec: Centralized Script Options (Delta)

## ADDED Requirements

### Requirement: Full Configuration Parity
100% of the `Options` table in `lls_core.lua` MUST be exposed in `mpv.conf` to prevent hidden state that cannot be adjusted by the user.

#### Scenario: Missing options in mpv.conf
- **WHEN** an option is added to the script's `Options` table
- **THEN** it must be added to `mpv.conf` with a corresponding comment if it involves user interaction.
