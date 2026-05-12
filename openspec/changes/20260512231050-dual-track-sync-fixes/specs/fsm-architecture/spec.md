## MODIFIED Requirements

### Requirement: Behavioral Parameterization
The system SHALL externalize all state transition thresholds to allow for hardware-specific tuning and scientific reliability.

#### Scenario: Tuning the settle period
- **WHEN** the user modifies `Options.nav_cooldown`
- **THEN** the FSM SHALL apply the new duration to subsequent seek events without requiring a reload.

#### Scenario: Manual Navigation Settle Period
- **WHEN** a manual seek is detected
- **THEN** the system SHALL suspend automated FSM corrections for a duration defined by `Options.nav_cooldown` (Default: 0.2s).

#### Scenario: Overlap Precision
- **WHEN** calculating transition points
- **THEN** a tolerance defined by `Options.nav_tolerance` (Default: 0.05s) SHALL be applied to handle floating-point rounding errors.
