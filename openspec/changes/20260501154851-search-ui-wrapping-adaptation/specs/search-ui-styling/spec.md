## ADDED Requirements

### Requirement: Dynamic Vertical Adaptation to Wrapped Content
The search interface SHALL dynamically adjust the height of its background elements and the vertical positioning of its components to accommodate wrapped text content in both the search input field and the results dropdown items.

#### Scenario: Multi-line Search Input
- **WHEN** a search query is long enough to wrap onto multiple visual lines within the 1200px box width
- **THEN** the search input field's background box SHALL expand vertically to contain all visual lines, and the results dropdown SHALL shift downwards to prevent overlap.

#### Scenario: Multi-line Search Results
- **WHEN** a search result item wraps onto multiple visual lines
- **THEN** the results dropdown background SHALL expand to accommodate the additional lines, and subsequent items in the list SHALL be correctly offset to prevent vertical overlap.
