## Why

This change formalizes the Drum Sync & Compatibility Guards introduced in Release v1.2.4. Following the v1.2.0 FSM migration, regressions were identified where high-frequency tick loops overwritten user commands (specifically for secondary subtitle positioning). Additionally, a need was identified for "Smart Guards" to prevent features like Context Copy or Drum Mode from being used in mismatched subtitle environments.

## What Changes

- Implementation of **Persistent State Tracking** for secondary subtitle positions via `FSM.native_sec_sub_pos` to prevent the 50ms tick loop from overwriting user `y` keypresses.
- Implementation of **Stale Array Flushing** in `update_media_state`. The system now detects subtitle path changes (including track disabling) and immediately clears memory arrays to prevent "ghost" subtitles.
- Introduction of **Smart Compatibility Guards** in `scripts/lls_core.lua`:
    - Secondary Position (`y`): Restricted to SRT tracks with active secondary subtitles.
    - Copy Mode (`Ctrl+Z`): Restricted to ASS or dual-track configurations.
    - Context Copy (`Ctrl+X`): Restricted to external subtitle files.
    - Drum Mode (`c`): Restricted to active subtitle tracks.

## Capabilities

### New Capabilities
- `drum-sync-compatibility-guards`: Mechanisms for ensuring state persistence against high-frequency tick overrides and safeguarding feature execution based on subtitle format and availability.

### Modified Capabilities
- None (Feature hardening).

## Impact

- **UI Responsiveness**: Commands like `y` and `j` now take effect instantly and persist.
- **System Stability**: Prevents rendering errors and logical failures by blocking features in unsupported subtitle contexts.
- **User Experience**: Clear OSD feedback is provided when a guarded feature is blocked.
