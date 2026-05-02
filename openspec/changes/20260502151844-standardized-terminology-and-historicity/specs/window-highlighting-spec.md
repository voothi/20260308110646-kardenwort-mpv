## ADDED Requirements

### Requirement: Dual-Notation Color Enforcement
All highlight colors SHALL be specified using the project's dual-notation standard to eliminate RGB/BGR ambiguity.

#### Scenario: Defining Gold Highlight
- **WHEN** the "Gold" cursor color is defined in the specification
- **THEN** it SHALL be written as `Gold (BGR: 00CCFF | RGB: #FFCC00)`

### Requirement: Canonical Name Synchronization
The specification SHALL use the canonical names defined in the `standardized-terminology-and-historicity` spec.

#### Scenario: Referencing Warm Path
- **WHEN** describing the contiguous selection-to-match flow
- **THEN** it SHALL be referred to as the "Warm Path"
