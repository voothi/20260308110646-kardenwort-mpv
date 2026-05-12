## ADDED Requirements

### Requirement: Replay Template Engine
The system SHALL provide a lightweight template engine for formatting replay-related OSD messages.

#### Scenario: Placeholder Substitution
- **WHEN** a template string contains `%m`
- **THEN** it SHALL be replaced by the value of `Options.replay_ms`.
- **WHEN** a template string contains `%c`
- **THEN** it SHALL be replaced by the value of `Options.replay_count`.
- **WHEN** a template string contains `%x`
- **THEN** it SHALL be replaced by a conditional string based on whether `Options.replay_count > 1`.
  - For `replay_msg_format`, `%x` becomes `" x" .. count`.
  - For `replay_on_msg_format`, `%x` becomes `" (x" .. count .. ")"`.

#### Scenario: Default Template Fallback
- **WHEN** no custom template is provided in `mpv.conf`
- **THEN** the system SHALL fall back to:
  - `replay_msg_format`: `"Replay: %mms%x"`
  - `replay_on_msg_format`: `"Replaying segment: %mms%x"`
