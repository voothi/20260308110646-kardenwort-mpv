## Why

Users who utilize external Text-to-Speech (TTS) applications to listen to subtitle text currently face high cognitive friction when trying to manually copy the subtitle text and trigger the correct target TTS voice. This change introduces a one-press TTS digit bindings capability in Kardenwort, allowing users to automatically copy clean subtitles and trigger specific system-wide TTS hotkeys with a single keypress (e.g. digits `2`..`5`). Additionally, standard video adjustments that previously occupied digits `1`..`4` are migrated to layout-independent letter keys (`o`/`p`/`k`/`l` and Cyrillic equivalents `щ`/`з`/`л`/`д`), which frees up the digits and avoids layout-related binding collisions.

## What Changes

- **Added Configurable TTS bindings**: Implemented `tts_trigger_enabled`, `tts_hotkey_1` through `tts_hotkey_8`, and `key_tts_1` through `key_tts_8` configuration options in `main.lua` and `mpv.conf`.
- **Layout-independent video adjustments**: Remapped video adjustments from `1`/`2`/`3`/`4` to layout-independent letters `o`/`p`/`k`/`l` and their Cyrillic counterparts `щ`/`з`/`л`/`д`.
- **Unignored digits in input.conf**: Removed hard `ignore` bindings for active TTS digits `2`, `3`, `4`, `5` in `input.conf` so they can be handled by script bindings, while `1`, `6`, `7`, `8` remain explicitly ignored in the current profile.
- **Dynamic Help HUD integration**: Added `@help` documentation comments for the TTS bindings `copy-subtitle-tts-2` through `copy-subtitle-tts-5` in `input.conf`.
- **Regression guards**: Created a targeted regression suite `tests/acceptance/test_20260518115930_tts_digit_bindings.py` to assert correct presence of script-opts, hotkeys, input.conf ignore-override safety, and layout compatibility.

## Capabilities

### New Capabilities
- `tts-digit-bindings`: Outlines requirements for configurable TTS hotkeys, VK-based layout-independent trigger injection, unignored input.conf mappings, and dynamic Help HUD integration for digits `1`..`8`.

### Modified Capabilities
- `layout-agnostic-hotkeys`: Extended layout-agnostic mapping requirements to include standard video adjustments (`o`/`p`/`k`/`l` and Cyrillic equivalents `щ`/`з`/`л`/`д`) instead of absolute English alphanumeric or digit keys.

## Impact

- **Lua script**: `scripts/kardenwort/main.lua` (added options and binding handlers).
- **Configuration files**: `mpv.conf` (configured active TTS hotkeys/keys), `input.conf` (shifted video adjustments, unignored active TTS digits, and added Help HUD comments).
- **Tests**: `tests/acceptance/test_20260518115930_tts_digit_bindings.py`.
