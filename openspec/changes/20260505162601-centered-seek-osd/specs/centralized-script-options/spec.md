## MODIFIED Requirements

### Requirement: Full Configuration Parity
100% of the `Options` table in `lls_core.lua` MUST be exposed in `mpv.conf` to prevent hidden state that cannot be adjusted by the user.

#### Scenario: Adding seek options and styling
- **WHEN** new seek parameters (logic, styling, templates) are added to the script's `Options` table
- **THEN** they MUST be added to `mpv.conf` with corresponding comments and `script-opts-append` entries.
- **AND** they MUST include `seek_msg_format` and `seek_msg_cumulative_format` with placeholder definitions.
