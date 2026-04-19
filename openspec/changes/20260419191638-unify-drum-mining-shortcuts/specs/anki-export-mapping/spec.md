## MODIFIED Requirements

### Requirement: Multi-Layout Export Triggering
The export mapping logic SHALL support multiple physical keys and layouts mapped to the same logical export action.

#### Scenario: Unified mining list configuration
- **WHEN** the `dw_key_add` configuration contains multiple keys (e.g., `MBTN_MID r к`)
- **THEN** any of these keys SHALL trigger the export mapping logic identically.
