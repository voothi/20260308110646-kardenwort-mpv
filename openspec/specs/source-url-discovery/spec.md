# Source URL Discovery

## Purpose
Automate the discovery and extraction of media source URLs from external sidecar files to enrich Anki export metadata.
## Requirements
### Requirement: Automatic Source Discovery
The system SHALL search the media directory for sidecar files containing URL metadata.
- **Matched Files**: `<media_base_name>.<ext>` (ext: `.url`, `.txt`, `.md`).
- **Patterns**: Lines matching `URL=<url>`.

#### Scenario: Valid .url file found
- **WHEN** a file named `video.url` exists with content `URL=https://example.com`
- **THEN** the system SHALL extract and cache the URL.

### Requirement: Anki Metadata Mapping
Discovered media source URLs SHALL be made available to the Anki export engine via a standardized keyword to ensure metadata accessibility in the resulting flashcards.

#### Scenario: source_url Field Mapping
- **WHEN** a media source URL is successfully discovered and cached.
- **AND** the `anki_mapping.ini` configuration contains a field mapped to the `source_url` keyword.
- **THEN** the system SHALL populate that field with the discovered URL during every export.

### Requirement: Discovery Resilience
The system SHALL ensure the URL metadata remains accurate throughout the playback session while minimizing filesystem interrogation.
- **Cache Invalidation**: If the source file is deleted or renamed, the cache MUST be invalidated.
- **Periodic Sync**: Triggers discovery every `anki_sync_period` seconds to support files added after media initialization.
- **Change Detection**: The system SHOULD implement metadata-based change detection (fingerprinting) on discovered source files to avoid redundant directory scanning and file re-parsing if the target directory state remains unchanged.

#### Scenario: Optimized URL Discovery
- **WHEN** the periodic sync triggers URL discovery
- **AND** a source file has already been identified and its fingerprint matches the disk state
- **THEN** the system SHALL reuse the cached metadata without rescanning the directory or re-reading the file.

