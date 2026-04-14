## Why

Multi-word term highlighting is failing for certain matching phrases (such as "Während massiv ausbauen konnten" and "massiv ausbauen konnten"), causing them not to display in the expected highlight colors on the Drum Window. Split terms should appear purple, and contiguous multi-word terms should appear orange, but they are currently missing these highlights, likely due to a bug in TSV parsing or matching logic.

## What Changes

- Fix the multi-word term parsing and matching logic in the Drum Window renderer.
- Ensure that split (non-contiguous) multi-word terms correctly match and display in purple.
- Ensure that contiguous multi-word terms correctly match and display in orange.

## Capabilities

### New Capabilities

### Modified Capabilities
- `anki-highlighting`: Update requirements to specify exact matching strategies for split (non-contiguous) terms and contiguous multi-word terms to avoid false negatives.

## Impact

- Drum Window subtitle rendering logic (`drum.lua` or similar).
- Word history matching and highlighting logic for Anki exports.
