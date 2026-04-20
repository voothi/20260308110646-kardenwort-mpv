## ADDED Requirements

### Requirement: Weighted Temporal Highlight Expansion
The highlight engine MUST apply temporal window expansion using a surplus-only weighted formula to ensure stability for long phrases without excessive buffer bloat.
- **Base Buffer**: `anki_local_fuzzy_window` (e.g. 10.0s).
- **Expansion Rate**: 0.5s per word.
- **Application Threshold**: Expansion applies ONLY to words beyond the 10th word in a term.
- **Formula**: `Window = Base + (max(0, WordCount - 10) * ExpansionRate)`.

#### Scenario: Expanding window for a long phrase
- **WHEN** a 12-word phrase is rendered
- **THEN** the highlight window SHALL be `Base + (2 * 0.5) = Base + 1.0s`.
- **AND** a 10-word phrase SHALL have NO expansion (`Base + 0.0s`).

### Requirement: Systemic Interaction Shield Lockout
The interaction engine SHALL enforce a uniform 150ms lockout for all mouse events following a keyboard-based interaction, governed by a single configurable parameter.
- All navigational and input handlers (Arrows, Enter, a/d, etc.) MUST utilize `Options.dw_mouse_shield_ms`.
- Hardcoded constants for lockout durations are STRONGLY DISCOURAGED.

#### Scenario: Keyboard command triggers shield
- **WHEN** the user presses 'Arrow Down'
- **THEN** the system SHALL set the mouse lock using the value from `dw_mouse_shield_ms`.
- **AND** subsequent mouse clicks SHALL be ignored for at least that duration.
