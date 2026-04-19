## ADDED Requirements

### Requirement: Automatic Source Discovery
The system SHALL search the media directory for sidecar files containing URL metadata whenever an Anki export is requested or during periodic synchronization.

#### Scenario: Base Name Match
- **WHEN** a file named `<media_base_name>.<ext>` exists (where ext is `.url`, `.txt`, or `.md`)
- **AND** the file contains a line matching `URL=<url>`
- **THEN** the system SHALL extract the URL and associate it with the current media session.

#### Scenario: Fallback Scoped Search
- **WHEN** no base-name-matched file is found
- **AND** at least one `.url` file exists in the media directory
- **THEN** the system SHALL attempt to extract the URL from the first `.url` file found alphabetically.

### Requirement: Discovery Resilience
The system SHALL ensure the URL metadata remains accurate even if files are modified, renamed, or deleted during a playback session.

#### Scenario: Cache Validation
- **WHEN** a URL is cached from a source file
- **AND** that source file is deleted or renamed
- **THEN** the system SHALL invalidate the cache and re-trigger discovery.

#### Scenario: Periodic Synchronization
- **WHEN** `anki_sync_period` is greater than 0
- **THEN** the system SHALL re-trigger discovery at every sync interval if no URL is currently cached, supporting files added after the video was opened.
