# Specification: Playback Change Interface

## Requirements

### Requirement: Single-Action Playback Change Contract
The system MUST provide a standardized request contract before playback-mechanism edits are implemented.

#### Scenario: Contract is prepared before implementation
- **WHEN** a user requests a playback behavior fix
- **THEN** the request MUST be captured with explicit fields: Goal, Trigger, Expected Behavior, Must-Not-Change, Acceptance, and Patch Scope
- **AND** implementation work MUST reference this contract as its source of truth.

### Requirement: Non-Regression Boundary Declaration
The contract MUST include explicit boundaries to prevent unrelated regressions.

#### Scenario: Scope boundaries are enforced
- **WHEN** a playback fix is prepared
- **THEN** the contract MUST name unaffected behavior domains (for example ordinary PHRASE forward playback, MOVIE baseline, Drum Window UI)
- **AND** acceptance MUST include at least one scenario verifying boundary preservation.
