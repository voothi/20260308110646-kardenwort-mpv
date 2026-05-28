## Why

The console output of the `scripts/_tools/sub-tts/sub_tts.py` tool during the TTS synthesis and speed adjustment stages prints a new line for every single subtitle cue (e.g. 274 separate lines). This floods the terminal, making it hard to read other crucial information and diagnostics. Furthermore, the cue index brackets (e.g. `[1/274]`) in the speed adjustment phase are displayed in the default text color rather than a dim grey style, causing inconsistency with the premium pip-style console output theme.

Improving these visual elements with an interactive, in-place progress bar (similar to the one in `youtube-downloader`) and standardizing the text styling will deliver a premium, state-of-the-art developer experience that aligns with the project's design aesthetics.

## What Changes

- **In-place Cue Progress Bar**: Replace the multi-line print outputs of both the TTS Synthesis and the Speed Adjustment stages with an elegant, carriage-returned progress bar that updates in-place when running in a TTY environment.
- **Robust non-TTY Logging**: In non-TTY environments, fall back to line-based logging but throttle the frequency (e.g. outputting progress updates at regular percentage thresholds) to prevent log bloating.
- **Pip-style Consistent Brackets**: Wrap progress counters in the dim grey `_dim` styling during both the synthesis and speed adjustment loops to ensure uniform visual consistency.
- **Clear terminal outputs**: Ensure the carriage-returned line is properly cleared upon completion so that final status summaries and success messages are printed cleanly.

## Capabilities

### New Capabilities
<!-- Capabilities being introduced. Replace <name> with kebab-case identifier (e.g., user-auth, data-export, api-rate-limiting). Each creates specs/<name>/spec.md -->

*None.*

### Modified Capabilities
<!-- Existing capabilities whose REQUIREMENTS are changing (not just implementation).
     Only list here if spec-level behavior changes. Each needs a delta spec file.
     Use existing spec names from openspec/specs/. Leave empty if no requirement changes. -->
- `sub-tts-pipeline`: Update the progress reporting requirements to specify a premium, dynamic, in-place progress bar for the TTS synthesis and speed adjustment phases, and standardize pip-style dim grey progress counter brackets.

## Impact

- **Affected code**: `scripts/_tools/sub-tts/sub_tts.py`
- **APIs & Dependencies**: No external dependencies or API changes. The changes are fully localized to stdout/stderr stream formatting.
