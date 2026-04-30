## ADDED Requirements

### Requirement: Word-Mapped Highlight Indexing
The system SHALL maintain a high-performance index (`FSM.ANKI_WORD_MAP`) of all loaded Anki highlights to allow O(1) lookups during rendering. The word map SHALL be a normalized lookup table keyed by lowercased word text, mapping to an array of matching highlight records.

#### Scenario: Subtitle Line Rendering
- **WHEN** a subtitle line is being rendered and highlights must be calculated for each word
- **THEN** the system SHALL retrieve relevant highlights directly from the word map instead of performing a linear scan of the entire database.

#### Scenario: Word map rebuild on TSV reload
- **WHEN** the periodic TSV sync detects a file change and reloads the highlight database
- **THEN** the `FSM.ANKI_WORD_MAP` SHALL be rebuilt atomically from the new database.
- **AND** all rendering caches SHALL be invalidated.

### Requirement: Hierarchical Rendering Caching
The rendering engine SHALL implement two tiers of caching: Layout Caching (at the subtitle level) and Draw Caching (at the track level).

#### Scenario: Static Playback
- **WHEN** the video is playing but the active subtitle index and highlight state remain constant
- **THEN** the system SHALL reuse the cached OSD string from `DRUM_DRAW_CACHE` to eliminate redundant CPU cycles.

#### Scenario: Visual Refresh
- **WHEN** the highlight database is updated (e.g., a new word is saved)
- **THEN** all rendering caches SHALL be invalidated and re-calculated on the next tick.

#### Scenario: Subtitle Index Change
- **WHEN** playback advances to a new subtitle entry
- **THEN** the layout cache for the previous entry MAY be retained, but the draw cache SHALL be invalidated.

### Requirement: Transparent Caching Invariant
The rendering output SHALL be byte-identical with and without caching enabled. Caching is purely a performance optimization and SHALL NOT alter any visual output.

#### Scenario: Cache correctness verification
- **WHEN** the draw cache produces a cached OSD string
- **AND** a full re-render is forced (e.g., by invalidating the cache)
- **THEN** the re-rendered OSD string SHALL be identical to the cached version.
