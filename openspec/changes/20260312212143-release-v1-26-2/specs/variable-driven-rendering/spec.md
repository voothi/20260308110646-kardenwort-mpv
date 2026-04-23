## ADDED Requirements

### Requirement: Dynamic ASS Template Substitution
The UI rendering engine SHALL generate ASS formatting tags dynamically based on the current values of the `Options` styling parameters.

#### Scenario: Rendering a search hit
- **WHEN** the OSD renders a matching character
- **THEN** it SHALL use the value from `Options.search_hit_color` to construct the `\c&H...&` tag, rather than a hardcoded value.
