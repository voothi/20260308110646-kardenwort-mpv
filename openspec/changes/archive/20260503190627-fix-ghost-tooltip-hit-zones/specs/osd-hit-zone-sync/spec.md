## MODIFIED Requirements

### Requirement: Priority-Based Hit-Test Arbitration
The hit-test engine SHALL support a tiered priority system where layers can be temporarily disabled or invalidated to prevent interaction bleed-through.

#### Scenario: Layer Invalidation
- **WHEN** a higher-priority layer (e.g., Tooltip) is logically inactive or suppressed
- **THEN** the hit-test engine MUST bypass this layer entirely and proceed to the next available layer (e.g., Drum Window).

#### Scenario: Metadata Lifecycle Enforcement
- **WHEN** any OSD layer is cleared visually
- **THEN** its corresponding hit-zone metadata MUST be invalidated in the same cycle to maintain visual-to-logical parity.
