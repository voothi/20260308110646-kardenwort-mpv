## Why

When secondary subtitle tracks or master subtitle visibility are disabled, users experience several friction points in Drum Window (DW) mode and interactive actions. Specifically, keybindings like tooltip toggling show an error ("X") when subtitles are turned off, and translation context harvesting fails because the secondary track is visually disabled, despite cached translation data being available. Furthermore, the `anki_highlight_bold` configuration is not respected for multi-word matches from the database, leading to highlighting inconsistencies.

## What Changes

- **Visibility Resilience in Drum Window**: Modify FSM subtitle visibility guards so that interactive commands (such as tooltips, copy popups, search, and smart additions) bypass the native subtitle visibility check if the Drum Window is currently active (`FSM.DRUM_WINDOW ~= "OFF"`).
- **Bold Highlight Parity**: Update highlight styling logic to ensure that phrase-only database highlights dynamically respect the `anki_highlight_bold` setting (rendering with bold `{\b1}` tags when set to yes, and regular `{\b0}` weight when set to no), while keeping manual selections strictly to regular weight.
- **Cache-Backed Copying and Context Harvesting**: Enhance copy and context harvesting routines (such as Shift+C and Shift+Q) to fall back to the preloaded subtitle cache `FSM.DW_TOOLTIP_SEC_SUBS` when the secondary track is visually disabled (`Tracks.sec.path` is nil or empty).

## Capabilities

### New Capabilities
- None

### Modified Capabilities
- `anki-highlighting`: Ensure that phrase-only database highlights dynamically respect the `anki_highlight_bold` configuration state, maintaining parity between single-word and multi-word database matches.
- `drum-window-navigation`: Allow interactive keybindings (e.g. `e`, `f`, `g`, `h`) inside the Drum Window when master subtitle visibility is toggled OFF by checking the active Drum Window state.
- `context-copy`: Enable cyclic copy modes and dictionary lookup harvesting in Subtitle Mode B using cached secondary subtitle track (`FSM.DW_TOOLTIP_SEC_SUBS`) when the secondary translation track is visually disabled.

## Impact

- `scripts/kardenwort/main.lua`: The central interaction and FSM routines are updated.
- `tests/acceptance/test_20260521111616_visibility_resilience.py`: Verify visibility resilience and bold highlighting parity behavior.
- `tests/acceptance/test_20260427003254_copy_sub_fallback.py`: Verify Mode B copy fallback tests when secondary subtitles are disabled.
