## Why

Split-term (purple) highlights in the Drum Window fail when constituent words span multiple subtitle segments or exceed the previous 2.0s temporal gap limit. This ensures consistent highlighting for elliptical phrases like "Hören ... sind" that wrap across line boundaries.

## What Changes

- **Increased Temporal Tolerance**: Expand the split-phrase search window to 10 lines and 12 seconds.
- **Improved Grounding**: Implement anchor-independent fallback for split-terms to handle inaccurate TSV indices (e.g., index drift or manual edits).
- **Export Consistency**: Fix the anchor index propagation in multi-word `Ctrl+Select` exports.
- **Indentation Refinement**: Standardize indentation in `load_anki_mapping_ini`.

## Capabilities

### New Capabilities
- None

### Modified Capabilities
- `anki-highlighting`: Relax temporal and segment constraints for split-phrase identification and permit unanchored matching as a fallback.

## Impact

- **Core Script**: `scripts/lls_core.lua` logic for `calculate_highlight_stack` and `ctrl_commit_set`.
- **Database Consistency**: Improved accuracy of future TSV exports.
