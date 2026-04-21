## MODIFIED Requirements

### Requirement: Discovery Resilience
The system SHALL ensure the URL metadata remains accurate throughout the playback session while minimizing filesystem interrogation.
- **Cache Invalidation**: If the source file is deleted or renamed, the cache MUST be invalidated.
- **Periodic Sync**: Triggers discovery every `anki_sync_period` seconds to support files added after media initialization.
- **Change Detection**: The system SHOULD implement metadata-based change detection (fingerprinting) on discovered source files to avoid redundant directory scanning and file re-parsing if the target directory state remains unchanged.

#### Scenario: Optimized URL Discovery
- **WHEN** the periodic sync triggers URL discovery
- **AND** a source file has already been identified and its fingerprint matches the disk state
- **THEN** the system SHALL reuse the cached metadata without rescanning the directory or re-reading the file.
