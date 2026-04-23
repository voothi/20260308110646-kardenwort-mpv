# Spec: Unified Navigation Logic

## Context
Maintaining separate navigation paths for different UI modes increases complexity and the chance of inconsistent behavior.

## Requirements
- Use the internal `Tracks.pri.subs` table for all subtitle jumps.
- Calculate target timestamps based on the table entries rather than relying on mpv's `sub-start` properties.
- Ensure the logic is state-agnostic (works identically in Search Mode, Drum Mode, and Normal Mode).

## Verification
- Confirm that subtitle jumps are equally responsive regardless of whether the Drum Window or Search HUD is open.
- Verify that the jump target is consistent across all modes.
