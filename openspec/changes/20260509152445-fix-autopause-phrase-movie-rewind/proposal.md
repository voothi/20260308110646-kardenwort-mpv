## Why

In `Autopause ON, PHRASE/MOVIE` mode, subtitle navigation (via `Shift+a/d`) is currently hindered by the repeat/boundary logic that triggers a stop when entering a new subtitle's effective range. This causes "jerky" navigation and unexpected recording stops, which disrupts the user's flow. Additionally, regression tests are using inconsistent padding values compared to production defaults, leading to false negatives or fragile tests.

## What Changes

- **Fluid Navigation**: Modify navigation logic to suppress repeat/boundary stops and "recording end" triggers specifically during active rewind/forward jumps (`Shift+a/d`).
- **Mode-Switching Guard**: Temporarily treat jumps as occurring in `MOVIE` mode internally to ensure the video continues playing smoothly through subtitle transitions without the "slug" or "padding" pause being enforced.
- **Padding Alignment**: Update the regression test suite and fixtures to use the standard 200ms `audio_padding_start` value (aligning with `lls-audio_padding_start=200` defaults).
- **LlsProbe Fix**: Fix a bug in the test harness where `_func_body` failed to find `LlsProbe` methods defined as table members rather than local functions.

## Capabilities

### New Capabilities
- None.

### Modified Capabilities
- `karaoke-autopause`: Suppress boundary pauses during manual subtitle navigation (`Shift+a/d`).
- `immersion-engine`: Ensure smooth state transitions between `PHRASE` and pseudo-`MOVIE` states during rapid jumps.
- `automated-acceptance-testing`: Align test suite padding constants with production defaults and fix `LlsProbe` method resolution.

## Impact

- `scripts/lls_core.lua`: Changes to `ctrl_jump_subtitle` and autopause logic.
- `tests/acceptance/`: Update padding values in integration tests.
- `tests/ipc/mpv_session.py`: Fix `LlsProbe` function resolution logic.
