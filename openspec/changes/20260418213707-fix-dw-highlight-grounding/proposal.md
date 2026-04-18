## Why

The Drum Window (Mode W) currently exhibits "highlight bleed," where identical phrases appearing in different subtitle segments are globally highlighted even when `anki-global-highlight` is disabled. This causes visual clutter and inaccurately indicates that a specific Anki record applies to multiple distinct occurrences.

## What Changes

- **Grounding Enforcement**: Refactor `calculate_highlight_stack` to strictly enforce $(time, index)$ anchoring for all contiguous highlights (Orange) when Global Highlights are OFF.
- **Traceback Logic**: Implement a cross-subtitle traceback mechanism to allow phrases spanning multiple subtitles to correctly match their specific anchor at the start point.
- **Improved Priority**: Ensure grounded matches are prioritized and bypass loose context matching when in local-only mode.

## Capabilities

### New Capabilities
- None

### Modified Capabilities
- `window-highlighting-spec`: Enforce strict index-driven grounding to prevent highlight bleed across identical terms.

## Impact

- `scripts/lls_core.lua`: Significant logic update to the highlighting engine.
- Anki Export Logic: Improved reliability of record-to-subtitle association.
