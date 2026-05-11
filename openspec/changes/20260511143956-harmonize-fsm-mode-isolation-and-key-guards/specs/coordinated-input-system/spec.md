## ADDED Requirements

### Requirement: Encountered Accidental Keys Are Explicitly Ignored
The keymap SHALL maintain a documented ignore list for accidental/default keys encountered during routine use to prevent blind state changes.

#### Scenario: ignored key does not mutate FSM
- **GIVEN** a key listed as `ignore` in `input.conf`
- **WHEN** it is pressed in any main mode (`srt`, `dm`, `dw`)
- **THEN** no mode-owned FSM field SHALL change as a direct result.

#### Scenario: ignore additions are reviewable
- **GIVEN** a newly discovered accidental key
- **WHEN** it is added to `input.conf`
- **THEN** it SHALL be grouped in a dedicated ignore section with a short rationale comment.
