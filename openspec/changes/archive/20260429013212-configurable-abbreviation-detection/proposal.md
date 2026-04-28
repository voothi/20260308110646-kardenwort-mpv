## Why

The current abbreviation detection logic in `is_abbrev` is hardcoded. Users may need to add language-specific abbreviations or toggle the smart regex-based detection to avoid false positives or enable better coverage for specific subtitle sources.

## What Changes

- Add `anki_abbrev_list` option (string) to `Options` in `lls_core.lua` to allow a custom list of space-separated abbreviations.
- Add `anki_abbrev_smart` option (boolean) to toggle the heuristic-based abbreviation patterns.
- Refactor `is_abbrev` to check against the user-defined list and respect the smart detection toggle.
- Synchronize these new parameters to `mpv.conf` and `lls.conf` with appropriate documentation.

## Capabilities

### New Capabilities

- `configurable-abbrev-detection`: Users can define a custom list of abbreviations and toggle smart detection via the configuration file.

## Impact

- `scripts/lls_core.lua`: `Options` table and `is_abbrev` function.
- `mpv.conf`: Documentation and default values.
- `lls.conf`: Default values.
