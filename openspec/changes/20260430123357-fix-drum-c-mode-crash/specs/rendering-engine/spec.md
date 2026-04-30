## MODIFIED Requirements

### Requirement: OSD Caching Stability
The system SHALL safely format all floating-point configuration parameters when generating cache keys to prevent runtime exceptions.

#### Scenario: Float-based line height multiplier
- **WHEN** the user configures a floating-point multiplier (e.g., `drum_line_height_mul=0.87`)
- **THEN** the rendering engine SHALL successfully format the cache key without throwing integer coercion errors.
