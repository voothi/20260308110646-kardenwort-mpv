## Why

Currently, Anki exports in Kardenwort-mpv lack a way to automatically associate a source URL with exported records when the media is sourced from external platforms like YouTube. This results in missing metadata or requires manual entry, reducing the efficiency of the vocabulary mining workflow.

## What Changes

- **Automatic URL Discovery**: Implementation of a scanner that searches for `.url`, `.txt`, and `.md` files in the media folder to extract `URL=` parameters.
- **Dynamic Source Mapping**: Introduction of the `source_url` internal data source for Anki field mapping.
- **Live Sync Integration**: Addition of URL discovery to the periodic synchronization loop (defaulting to the configured `anki_sync_period`).
- **Resilient Caching**: Implementation of a file-path-aware cache that invalidates and re-scans if the source file is deleted or renamed.

## Capabilities

### New Capabilities
- `source-url-discovery`: Defines the logic for discovering, parsing, and validating external URL sources in the media directory.

### Modified Capabilities
- `anki-export-mapping`: Add the `source_url` keyword to the list of resolvable data sources for Anki field configuration.

## Impact

- `scripts/lls_core.lua`: Main logic for discovery and resolution.
- `script-opts/anki_mapping.ini`: Default mappings for the `SourceURL` field.
- Periodic synchronization performance (minimal impact due to caching).
