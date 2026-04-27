## Why

Toggling subtitle visibility with the `s/ы` key stopped working when Drum Mode (Mode C) is active. This is because the current rendering logic treats Drum Mode as a master visibility control that overrides the native subtitle visibility state. Users need to be able to quickly hide subtitles even in Drum Mode to test their hearing, which is a core part of the language learning workflow.

## What Changes

- **Unified Visibility Control**: Ensure that the `s/ы` key (which toggles `FSM.native_sub_vis`) acts as a master "kill switch" for all subtitle rendering, including custom OSD modes.
- **Logic Refinement**: Update the `pri_use_osd` and `sec_use_osd` logic in `master_tick` to respect the `FSM.native_sub_vis` and `FSM.native_sec_sub_vis` flags respectively.
- **Specification Correction**: Update the `subtitle-rendering` specification to remove the requirement that Drum Mode overrides native visibility.

## Capabilities

### New Capabilities
- None

### Modified Capabilities
- `subtitle-rendering`: Fix the priority of the visibility toggle (`s` key) so it correctly hides custom OSD subtitles even when Drum Mode is ON.

## Impact

- **LLS Core**: Modification of `master_tick` rendering logic in `scripts/lls_core.lua`.
- **Specifications**: Modification of `openspec/specs/subtitle-rendering/spec.md`.
- **UX**: Restores the ability to use the standard `s` key to "test your hearing" while using advanced rendering modes.
