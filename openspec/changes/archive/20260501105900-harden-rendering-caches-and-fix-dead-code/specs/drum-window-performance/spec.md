## MODIFIED Requirements

### Requirement: Layout Caching
The Drum Window rendering engine SHALL cache the calculated text layout (token positions, line heights, and hit-box boundaries).
- **Trigger-based Invalidation**: The cache MUST be invalidated if:
    - The current media track changes.
    - The viewport center (`FSM.DW_VIEW_CENTER`) moves.
    - The font size or spacing options are modified (via `LAYOUT_VERSION` increment).
    - A manual `flush_rendering_caches()` is called.
- **Persistence**: The cache SHALL persist between individual mouse-move events to avoid redundant O(N) calculations during high-frequency hit-testing.

#### Scenario: Moving mouse in Drum Window
- **WHEN** the user moves the mouse within the Drum Window.
- **THEN** the system SHALL use the cached layout for hit-testing instead of rebuilding the entire scene.
