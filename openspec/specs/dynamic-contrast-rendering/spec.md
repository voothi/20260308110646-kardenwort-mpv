## ADDED Requirements

### Requirement: State-Dependent Contrast
The system SHALL adjust the highlighting colors based on the selection state of the search result to ensure optimal legibility.

#### Scenario: Highlighting a selected result
- **WHEN** a search result is selected (visualized by switching to `Options.search_sel_color`)
- **THEN** the character hits SHALL be rendered in the primary highlight color (e.g., `Options.search_query_hit_color`) to ensure optimal contrast against the selection color.

### Requirement: Visual Truncation Guard
The system SHALL truncate search result lines to 120 characters to prevent OSD performance degradation from excessive style tagging.

#### Scenario: Rendering a long subtitle line
- **WHEN** a subtitle line exceeds 120 characters
- **THEN** the system SHALL truncate the string and append "..." before applying highlights and rendering.
