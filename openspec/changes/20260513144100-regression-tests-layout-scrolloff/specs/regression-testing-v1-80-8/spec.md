## ADDED Requirements

### Requirement: Regression Coverage for v1.80.8 Refinements
The system SHALL have automated acceptance tests that verify the stability of architectural fixes introduced in v1.80.8, specifically focusing on layout engine robustness and configuration edge cases.

#### Scenario: Verify layout engine stability after partial cache invalidation
- **WHEN** the subtitle layout cache contains partial or malformed entries (e.g., missing height metadata)
- **THEN** the system SHALL reject the invalid cache entries and perform a full layout rebuild
- **AND** the system SHALL NOT crash with arithmetic errors.

#### Scenario: Verify drum scrolloff clamping
- **WHEN** `drum_scrolloff` is set to `0` or other extreme values
- **THEN** the viewport margin SHALL be clamped to non-negative values
- **AND** the viewport selection logic SHALL behave predictably at the window boundaries.
