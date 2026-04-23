## Why

This change formalizes the Centralized Configuration & Safety Guards introduced in Release v1.2.10. The move to `mp.options` support allows for user-level customization via `mpv.conf` without Lua modifications. Additionally, the introduction of a mandatory "Safety Gap" addresses a critical visual regression where primary and secondary subtitles would collide at high Y-coordinate positions.

## What Changes

- Implementation of `mp.options` support in `lls_core.lua` to enable parameter overrides (`sec_pos_top`, `sec_pos_bottom`) from `mpv.conf`.
- Reintroduction of the **Safety Gap** logic: enforcing a 5% vertical gap between secondary (`sec_pos_bottom=90`) and primary (`sub-pos=95`) subtitles.
- Transition to **Threshold-Based Positional Logic**: replacing strict semantic equality with a `< 50` threshold to improve toggling robustness when custom positions are used.
- Expansion of **Native Russian Layout Support** for standard mpv commands (Quit, Mute, Speed, Frame Step) within the project's input configuration.

## Capabilities

### New Capabilities
- `centralized-script-config`: A mechanism for exposing internal script parameters to the player's global configuration file.
- `subtitle-safety-guards`: Logical constraints that prevent visual overlap and collision between multiple active subtitle tracks.
- `extended-layout-robustness`: Comprehensive mapping of standard player controls to alternative keyboard layouts.

### Modified Capabilities
- None (Configuration and logic hardening).

## Impact

- **Customizability**: Users can now tune script behavior through standard `mpv.conf` mechanisms.
- **Visual Integrity**: Elimination of subtitle "sticking" and overlapping issues in dual-track environments.
- **User Convenience**: Standard player commands now work natively in Russian keyboard layouts without manual switching.
