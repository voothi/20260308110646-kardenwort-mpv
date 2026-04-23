## ADDED Requirements

### Requirement: Explicit Z-Index Ordering
The system SHALL explicitly manage the stacking order of all OSD overlays to prevent visual overlap or occlusion.

#### Scenario: Rendering Search HUD over Drum Window
- **WHEN** the Search HUD is active while the Drum Window is visible
- **THEN** the system SHALL ensure the Search HUD remains on top by having a higher Z-index value (30 vs 20).
