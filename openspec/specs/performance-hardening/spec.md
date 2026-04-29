## ADDED Requirements

### Requirement: Word-Mapped Highlight Indexing
The system SHALL maintain a high-performance index (`FSM.ANKI_WORD_MAP`) of all loaded Anki highlights to allow $O(1)$ lookups during rendering.

#### Scenario: Subtitle Line Rendering
- **WHEN** A subtitle line is being rendered and highlights must be calculated for each word.
- **THEN** The system SHALL retrieve relevant highlights directly from the word map instead of performing a linear scan of the entire database.

### Requirement: Hierarchical Rendering Caching
The rendering engine SHALL implement two tiers of caching: Layout Caching (at the subtitle level) and Draw Caching (at the track level).

#### Scenario: Static Playback
- **WHEN** The video is playing but the active subtitle index and highlight state remain constant.
- **THEN** The system SHALL reuse the cached OSD string from `DRUM_DRAW_CACHE` to eliminate redundant CPU cycles.

#### Scenario: Visual Refresh
- **WHEN** The highlight database is updated (e.g., a new word is saved).
- **THEN** All rendering caches SHALL be invalidated and re-calculated on the next tick.
