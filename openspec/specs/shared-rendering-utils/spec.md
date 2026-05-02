# Capability: Shared Rendering Utilities

## ADDED Requirements

### Requirement: Standardized Alpha Calculation
The system SHALL provide a centralized function to convert opacity percentages (0-100) or hex strings (00-FF) into ASS alpha format.

#### Scenario: Decimal to Hex conversion
- **WHEN** opacity is provided as `0.6`
- **THEN** it SHALL be converted to the correct ASS transparency hex code.

### Requirement: Unified Token Wrapping
The rendering pipeline SHALL use a shared utility to wrap subtitle tokens into visual lines based on a target width and font metrics.

#### Scenario: Multi-line wrapping
- **WHEN** a subtitle exceeds the maximum OSD width
- **THEN** the shared utility SHALL return an array of visual line indices.

### Requirement: Standardized Hit-Zone Management
The system SHALL provide a unified method for registering and hit-testing OSD interactive regions across all modes.

#### Scenario: Interactive search result
- **WHEN** a search result is rendered
- **THEN** its hit-zones SHALL be registered using the shared rendering utility.
