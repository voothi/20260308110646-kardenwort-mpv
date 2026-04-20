# Source URL Discovery

## Purpose
Automate the discovery and extraction of media source URLs from external sidecar files to enrich Anki export metadata.

## Requirements

### Requirement: Automatic Source Discovery
The system SHALL search the media directory for sidecar files containing URL metadata.
- **Matched Files**: `<media_base_name>.<ext>` (ext: `.url`, `.txt`, `.md`).
- **Patterns**: Lines matching `URL=<url>`.

### Requirement: Anki Metadata Mapping
Discovered media source URLs SHALL be made available to the Anki export engine via a standardized keyword to ensure metadata accessibility in the resulting flashcards.

#### Scenario: source_url Field Mapping
- **WHEN** a media source URL is successfully discovered and cached.
- **AND** the `anki_mapping.ini` configuration contains a field mapped to the `source_url` keyword.
- **THEN** the system SHALL populate that field with the discovered URL during every export.

### Requirement: Discovery Resilience
The system SHALL ensure the URL metadata remains accurate throughout the playback session.
- **Cache Invalidation**: If the source file is deleted or renamed, the cache MUST be invalidated.
- **Periodic Sync**: Triggers discovery every `anki_sync_period` seconds to support files added after media initialization.
