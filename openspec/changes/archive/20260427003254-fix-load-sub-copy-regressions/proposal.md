## Why

Recent code implementations introduced regressions in subtitle extraction and loading. Specifically, the priority of internal versus native data sources was inverted, and a hard-coded character filter in the ASS loader broke support for translation tracks in that format.

## What Changes

- **Source Prioritization**: Refactored `cmd_copy_sub` to utilize internal track tables as the primary data source, falling back to native properties only if internal data is unavailable.
- **Fallback Logic Correction**: Fixed the selection of primary vs. secondary lines in `cmd_copy_sub` when language filtering falls back.
- **Loader Robustness**: Removed the restrictive Cyrillic filter from the ASS loader and expanded the SRT merging window to 10 entries for interleaved track support.

## Capabilities

### New Capabilities
<!-- None -->

### Modified Capabilities
- `context-copy`: Correcting implementation of "Unified Source Fallback" and "Language-Aware Fallback".
- `drum-window`: Extending "Robust Karaoke Merging" (10-entry window) to SRT tracks.

## Impact

- `scripts/lls_core.lua`: Modification of core loading and extraction functions.
- `openspec/specs/context-copy/spec.md`: Alignment with refined extraction requirements.
