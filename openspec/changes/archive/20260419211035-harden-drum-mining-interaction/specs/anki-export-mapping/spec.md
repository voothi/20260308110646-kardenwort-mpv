## MODIFIED Requirements

### Requirement: Multi-Layout Export Triggering
The export mapping logic SHALL support multiple physical keys and layouts mapped to the same logical export action, ensuring that mining is as efficient on minimalist remote controllers as it is on a full keyboard.

#### Scenario: Unified mining list configuration
- **WHEN** the `dw_key_add` configuration contains multiple keys (e.g., `MBTN_MID r к`)
- **THEN** any of these keys SHALL trigger the export mapping logic identically.
- **AND** the system SHALL automatically determine whether to export the standard yellow selection or the persistent paired set based on the presence of pink highlights.

#### Scenario: Context-Aware Smart Mining
- **WHEN** a mining trigger is activated
- **AND** the current word belongs to a persistent paired (Pink) set
- **THEN** the system SHALL export all members of that set using elliptical joiners where necessary.
- **ELSE** the system SHALL export the contiguous yellow selection range.
