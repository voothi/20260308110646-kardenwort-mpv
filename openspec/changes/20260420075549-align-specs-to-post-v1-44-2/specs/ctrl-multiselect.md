## ADDED Requirements

### Requirement: Persistent Selection Accumulator
The paired selection set (indicated by Pink highlights) SHALL persist indefinitely across modifier key releases and viewport navigation.

#### Scenario: Persistence Across Ctrl Release
- **WHEN** words are added to the `ctrl_pending_set` while holding a pairing modifier
- **AND** the user releases the modifier
- **THEN** the `ctrl_pending_set` SHALL NOT be cleared.
- **AND** the Pink highlights SHALL remain visible in the viewport.

### Requirement: Explicit Discard Gesture
The system SHALL provide a dedicated command to clear the persistent selection set.

#### Scenario: Discarding the set
- **WHEN** the user triggers the discard command (mapped to `Ctrl+ESC`)
- **THEN** the `ctrl_pending_set` SHALL be emptied immediately.

### Requirement: "Warm vs. Cool" Selection Colors
The system SHALL use distinct chromatic paths for different selection types.

#### Scenario: Cool Selection Path (Paired)
- **WHEN** the user is in "Pairing Mode" (Cool Path)
- **THEN** the cursor and pending words SHALL be rendered in **Neon Pink (#FF88FF)**.
- **AND** committed non-contiguous terms SHALL result in **Purple** highlights.

#### Scenario: Warm Selection Path (Contiguous)
- **WHEN** the user is in "Contiguous Mode" (Warm Path)
- **THEN** the focus and selection range SHALL be rendered in **Gold (#00CCFF)**.
- **AND** committed contiguous terms SHALL result in **Orange** highlights.
