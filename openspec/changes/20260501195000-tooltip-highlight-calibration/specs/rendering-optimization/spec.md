## ADDED Requirements

### Requirement: Parameter-Driven Token Colorization
The `populate_token_meta` architectural service SHALL support parameter-driven colorization to allow different rendering contexts (e.g., Drum Window vs. Tooltip) to apply distinct selection palettes without logic duplication.

#### Scenario: Multi-Context Coloration
- **WHEN** the system calls `populate_token_meta` from the Tooltip rendering loop
- **THEN** it SHALL pass context-specific highlight and control colors as arguments.
- **AND** the resulting token metadata SHALL reflect these specific colors instead of the default global Drum Window options.
