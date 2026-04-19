## ADDED Requirements

### Requirement: Search Placeholder Styling
The global search UI SHALL display a placeholder inscription when no query text has been entered. This placeholder SHALL consist of an active cursor and descriptive text to guide the user.

#### Scenario: Empty Search Query Visualization
- **WHEN** the user opens the global search interface and the search query buffer is empty
- **THEN** the system SHALL render an opaque cursor symbol (`|`) at the beginning of the input field.
- **AND** the system SHALL render the dimmed text "Search..." immediately following the cursor.

### Requirement: Search Results Selection
The search interface SHALL allow the user to navigate through results using keyboard inputs.

#### Scenario: Navigating Results
- **WHEN** results are present in the search UI
- **AND** the user presses the UP or DOWN arrow keys
- **THEN** the system SHALL update the selection index and highlight the corresponding result in the dropdown.
