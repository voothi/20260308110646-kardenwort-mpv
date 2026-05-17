## Why

Copy behavior in `Copy Subtitle Mode: B` was inconsistent: manual selections (yellow/pink) exported from the primary track while no-selection copy exported from secondary. In parallel, DW copy preview used byte slicing and could corrupt Cyrillic characters in OSD (for example `кладеÑ`).

## What Changes

- Unified copy-source selection in export preparation so `A/B` mode is applied consistently for `POINT`, `RANGE`, and `SET` export paths.
- Added UTF-8-safe truncation for DW copy preview text to prevent multibyte character corruption.
- Standardized DW preview construction through a shared helper for deterministic formatting.
- Added regression tests for UTF-8 truncation boundaries and copy preview integrity.
- Extended test instrumentation to make preview/truncation validation deterministic.

## Capabilities

### New Capabilities
- `utf8-safe-copy-preview`: Ensure copy preview truncation preserves UTF-8 character boundaries in OSD/tested preview strings.

### Modified Capabilities
- `context-copy`: Require `Copy Subtitle Mode: B` to use secondary-track source consistently for manual selection export paths.

## Impact

- Affected code:
  - `scripts/kardenwort/main.lua` (export source routing, preview formatting, test hooks)
  - `tests/acceptance/test_20260517200951_utf8_copy_preview.py` (new regression coverage)
- No breaking API changes for users; behavior becomes internally consistent and safer for Cyrillic/UTF-8 content.
- Improves reliability of copy workflows for dual-subtitle language-mining sessions.
