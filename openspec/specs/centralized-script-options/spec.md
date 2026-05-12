# Spec: Centralized Script Options

## Purpose
Decoupling configuration from code is essential for user-friendly customization.
## Requirements
- All adjustable parameters SHALL be moved from `kardenwort/main.lua` to `mpv.conf`.
- The `script-opts-append` syntax SHALL be used for the `kardenwort` identifier.
- Parameters SHALL include AutoPause thresholds, Drum Mode settings, Immersion Modes, and UI toggles.

### Requirement: Full Configuration Parity
100% of the `Options` table in `kardenwort/main.lua` MUST be exposed in `mpv.conf` to prevent hidden state that cannot be adjusted by the user.

#### Scenario: Missing options in mpv.conf
- **WHEN** an option is added to the script's `Options` table (e.g., `seek_time_delta`, `seek_font_size`, or `seek_msg_format`)
- **THEN** it must be added to `mpv.conf` with a corresponding comment and `script-opts-append` entry.
- **AND** for templates (like `seek_msg_format`, `replay_msg_format`), it MUST include placeholder documentation (`%p`, `%v`, `%m`, `%c`, etc.).

## Verification
- Verify that changes made to `script-opts` in `mpv.conf` are reflected in script behavior.
- Confirm that `kardenwort/main.lua` calls `mp.options.read_options`.



