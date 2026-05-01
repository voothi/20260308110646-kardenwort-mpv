## ADDED Requirements

### Requirement: Unified Cache Invalidation Key
The system SHALL ensure that all high-level draw caches (OSD and Drum Window) include the total count of Anki highlights in their invalidation criteria.
- **In-Memory Sync**: The system MUST detect changes to `FSM.ANKI_HIGHLIGHTS` size without requiring a full file-system poll on every tick.

#### Scenario: Visual feedback after record add
- **GIVEN** a word is selected and the Drum Window is visible
- **WHEN** the user saves the word to Anki (increasing the highlight count)
- **THEN** the Drum Window cache MUST invalidate immediately
- **AND** the next redraw MUST render the new highlight color on the target word.

### Requirement: Track-Aware OSD Caching
The Drum Mode rendering engine SHALL include the track source (primary vs secondary) in its result cache key to prevent visual collisions in dual-track mode.

#### Scenario: Dual-track playback
- **GIVEN** both primary and secondary subtitles are enabled in Drum Mode
- **WHEN** both tracks have the same logical index
- **THEN** the system MUST maintain separate cached ASS strings for each track
- **AND** the OSD SHALL correctly render both tracks without mirroring the content of one into the other.

### Requirement: Token-Level Highlight Memoization
The system SHALL memoize the results of expensive database highlight lookups (Level 3) at the token level.
- **Persistence**: Results MUST persist across redraws as long as the global highlight database and the parent subtitle's text remain unchanged.
- **Flush Trigger**: The memo MUST be cleared when `ANKI_HIGHLIGHTS` is modified or the subtitle track is reloaded.

#### Scenario: Rapid Redraw Performance
- **WHEN** the system redraws the same subtitle line multiple times (e.g., during cursor hover or small seeking adjustments)
- **THEN** the system SHALL skip `calculate_highlight_stack` for tokens with a valid memoized result
- **AND** CPU usage during high-frequency OSD updates SHALL be significantly reduced.

### Requirement: Pre-calculated Normalized Tokens
The tokenization engine SHALL pre-calculate and store normalized lowercase text for all word tokens during initial track load or subtitle entry processing.
- **Normalization**: The normalization MUST include case mapping and the removal of common punctuation/metadata brackets.

#### Scenario: Subtitle Loading
- **WHEN** a subtitle track is loaded or a new subtitle is encountered
- **THEN** every word token in that subtitle SHALL be assigned a `lower_clean` property
- **AND** subsequent highlight matching operations SHALL use this property instead of calling `utf8_to_lower` repeatedly.
