## MODIFIED Requirements

### Requirement: Layout Caching
The Drum Window rendering engine SHALL cache the calculated text layout (token positions, line heights, and hit-box boundaries).
- **Trigger-based Invalidation**: The cache MUST be invalidated if:
    - The current media track changes.
    - The viewport center (`FSM.DW_VIEW_CENTER`) moves.
    - The font size or spacing options are modified.
    - The `LAYOUT_VERSION` counter is incremented (which occurs whenever font/spacing options change or `flush_rendering_caches()` is called).
- **Consistency**: The viewport-level layout cache (`DW_LAYOUT_CACHE`) MUST respect the same `LAYOUT_VERSION` counter as the per-subtitle `sub.layout_cache` entries, ensuring both levels are invalidated together.
- **Persistence**: The cache SHALL persist between individual mouse-move events to avoid redundant O(N) calculations during high-frequency hit-testing.

#### Scenario: Moving mouse in Drum Window
- **WHEN** the user moves the mouse within the Drum Window.
- **THEN** the system SHALL use the cached layout for hit-testing instead of rebuilding the entire scene.

#### Scenario: Font size option change
- **WHEN** the user modifies a font size or spacing option.
- **THEN** `flush_rendering_caches()` SHALL be called, incrementing `LAYOUT_VERSION`.
- **AND** both `DW_LAYOUT_CACHE` and all `sub.layout_cache` entries SHALL be treated as invalid on the next render.
- **AND** the next draw call SHALL recompute wrapped lines and heights from scratch.
