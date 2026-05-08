## MODIFIED Requirements

### Requirement: Selection Range Feedback
The system SHALL provide immediate visual feedback during "Cool Path" (Pink) selections across all rendering modes (Drum Window, Drum Mode/Windowless, and SRT mode).
- **Color**: **Neon Pink (#FF88FF)**.
- **State**: Persistent until explicitly additive commit (MMB/Add) or explicit discard (ESC).

#### Scenario: Pink selection visibility
- **WHEN** the user selects a word in paired mode
- **THEN** it SHALL be colored Neon Pink (#FF88FF).

#### Scenario: Immediate Feedback in Drum Mode
- **WHEN** the user toggles a word into the paired selection set while in Drum Mode or SRT mode
- **THEN** the OSD MUST redraw immediately to reflect the Pink highlight.
