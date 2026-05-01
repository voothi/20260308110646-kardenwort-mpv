# Specification: Drum Window Performance

## Requirement: Layout Caching
The Drum Window rendering engine SHALL cache the calculated text layout (token positions, line heights, and hit-box boundaries).
- **Trigger-based Invalidation**: The cache MUST be invalidated if:
    - The current media track changes.
    - The viewport center (`FSM.DW_VIEW_CENTER`) moves.
    - The font size or spacing options are modified.
    - **[NEW]** The total count of Anki highlights changes (record added/removed).
- **Consistency**: The viewport-level layout cache (`DW_LAYOUT_CACHE`) MUST respect the same `LAYOUT_VERSION` counter as the per-subtitle `sub.layout_cache` entries, ensuring both levels are invalidated together.
- **Persistence**: The cache SHALL persist between individual mouse-move events to avoid redundant O(N) calculations during high-frequency hit-testing.

#### Scenario: Moving mouse in Drum Window
- **WHEN** the user moves the mouse within the Drum Window.
- **THEN** the system SHALL use the cached layout for hit-testing instead of rebuilding the entire scene.

#### Scenario: Record adding trigger
- **WHEN** a new record is added to Anki.
- **THEN** the Layout Cache SHALL be invalidated to ensure fresh highlight geometry is calculated.

#### Scenario: Font size option change
- **WHEN** the user modifies a font size or spacing option.
- **THEN** `flush_rendering_caches()` SHALL be called, incrementing `LAYOUT_VERSION`.
- **AND** both `DW_LAYOUT_CACHE` and all `sub.layout_cache` entries SHALL be treated as invalid on the next render.
- **AND** the next draw call SHALL recompute wrapped lines and heights from scratch.

### Requirement: Optimized TSV Persistence
Adding a new favorite/Anki mining record SHALL NOT trigger a full reload of the TSV file.
- **Append-Only Memory Sync**: The system SHALL append the new record to the internal `ANKI_HIGHLIGHTS` table immediately upon a successful file write.
- **Async Consistency**: A full re-sync SHALL only occur via the periodic background timer or when the file fingerprint (size/mtime) changes unexpectedly.

#### Scenario: Adding a word to favorites
- **WHEN** the user saves a new word.
- **THEN** the word SHALL appear as highlighted immediately without a noticeable pause for file re-parsing.
