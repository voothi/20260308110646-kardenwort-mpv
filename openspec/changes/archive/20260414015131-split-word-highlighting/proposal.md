## Why

The user wants to export and highlight non-contiguous ("split") paired words. Currently, after adding a multi-word selection involving non-contiguous words via the Ctrl+LMB and Ctrl+MMB combo, the selected words lose their selection highlight (orange) and return to their original color without receiving a persistent "added" highlight. Non-contiguous selections need a distinct, persistent highlight color (like purple) to clearly indicate their association and successful export, enhancing visual feedback in the Drum Window.

## What Changes

- Introduce a new highlighting color (`purple` or similar) to represent successfully exported non-contiguous multi-word pairings.
- Update the word highlighting logic so that matching non-contiguous exports retain their visual highlight when rendered in a subtitle line.
- Update the TSV reading and parsing logic to recognize and highlight non-contiguous terms that have been previously exported.

## Capabilities

### New Capabilities

### Modified Capabilities
- `ctrl-multiselect`: Handling visual persistence and indication of non-contiguous multi-word selections post-export.
- `anki-highlighting`: Extending the highlighting rules and color palette to support purple for non-contiguous paired words.

## Impact

- Visual rendering logic in the Drum Window (likely `lls_core.lua` or UI drawing code).
- The Anki export definition parsing and matching routines that check TSVs for previously exported terms.
