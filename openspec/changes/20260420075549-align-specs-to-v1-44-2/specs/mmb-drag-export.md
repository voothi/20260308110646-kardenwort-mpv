## ADDED Requirements

### Requirement: Chromatic Alignment (v1.44.2)
MMB-triggered selections SHALL align with the unified "Warm vs. Cool" color system.

#### Scenario: Drag-Selection Color
- **WHEN** the user drags with MMB (without pairing modifiers)
- **THEN** the active range SHALL be rendered in **Gold (#00CCFF)**.

#### Scenario: Post-Commit Color
- **WHEN** the selection is committed (released)
- **THEN** the words SHALL transition to the appropriate saved color:
    - **Orange** for contiguous spans.
    - **Purple** for fragments identified as split terms.
