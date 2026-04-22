## ADDED Requirements

### Requirement: Categorized Configuration Structure
The `input.conf` file SHALL be organized into logical functional groups to improve readability.

#### Scenario: Auditing input configuration
- **WHEN** the user opens `input.conf`
- **THEN** they SHALL find clearly delineated sections for Navigation, Language Layouts, and Feature Toggles.

### Requirement: Inline Behavioral Instructions
Every keybinding in the configuration SHALL include a descriptive comment explaining its purpose and any specialized behavior.

#### Scenario: Discovering feature nuances
- **WHEN** the user inspects the `LEFT` arrow binding in `input.conf`
- **THEN** they SHALL find a comment explaining that it is fixed to 2 seconds for precise phrase navigation.
