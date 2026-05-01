## ADDED Requirements

### Requirement: Layout-Aware Mouse Interaction
The Search HUD SHALL support precise mouse interaction that accounts for multi-line wrapping in both the search query and the results list.

#### Scenario: Clicking a wrapped result
- **WHEN** a search result spans multiple visual lines
- **THEN** the system SHALL correctly map the click coordinates to the logical result index, regardless of the line count.

### Requirement: Search Aesthetic Parity
The Search HUD SHALL adhere to the v1.58.0 "Premium" aesthetic standards, including synchronized transparency for all UI components.

#### Scenario: Background Box Rendering
- **WHEN** the Search HUD background box is rendered
- **THEN** it SHALL use synchronized `\3a` and `\4a` tags matching the background opacity to eliminate blooming or high-contrast borders.
