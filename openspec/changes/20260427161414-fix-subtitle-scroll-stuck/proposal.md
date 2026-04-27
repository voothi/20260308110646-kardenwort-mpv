## Why

Navigation (seeking to the next subtitle) becomes stuck on specific phrases when generic tags like `[Music]` or `[Музыка]` appear non-consecutively in the subtitle file. This occurs because the script's merging logic aggressively combines identical lines across a 10-line window, causing intermediate unique subtitles to be "swallowed" in the internal index-based table, leading to infinite loops during forward seeking.

## What Changes

- **Subtitle Merging Logic**: Restrict subtitle merging to only immediately preceding lines with identical text.
- **Temporal Threshold**: Implement a 200ms maximum gap threshold for merging; lines with identical text separated by more than 200ms will be treated as distinct seek targets.
- **Sorting Reliability**: Ensure all internal subtitle tracks (SRT and ASS) are explicitly sorted by start time to maintain navigational consistency.

## Capabilities

### New Capabilities
- None

### Modified Capabilities
- `reliable-subtitle-seeking-custom-logic`: Update seeking and loading requirements to ensure non-consecutive identical subtitles are preserved as independent navigational nodes.
- `scanner-parser`: Refine merging rules during the parsing phase to prevent loss of intermediate subtitle data.

## Impact

- **LLS Core**: `scripts/lls_core.lua` (specifically `load_sub` and `cmd_dw_seek_delta` logic).
- **Navigation UX**: Users will no longer experience "stuck" subtitles when scrolling through segments with repetitive background tags.
