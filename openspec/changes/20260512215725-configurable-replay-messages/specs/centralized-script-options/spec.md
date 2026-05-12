## MODIFIED Requirements

### Requirement: Full Configuration Parity
100% of the `Options` table in `kardenwort/main.lua` MUST be exposed in `mpv.conf` to prevent hidden state that cannot be adjusted by the user.

#### Scenario: Missing options in mpv.conf
- **WHEN** an option is added to the script's `Options` table (e.g., `seek_time_delta`, `seek_font_size`, or `seek_msg_format`)
- **THEN** it must be added to `mpv.conf` with a corresponding comment and `script-opts-append` entry.
- **AND** for templates (like `seek_msg_format`, `replay_msg_format`), it MUST include placeholder documentation (`%p`, `%v`, `%m`, `%c`, etc.).
