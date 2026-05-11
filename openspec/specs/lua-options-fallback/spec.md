# Spec: Lua Options Fallback

## Context
The script must remain functional even if external configuration is missing or broken.

## Requirements
- Maintain a local `Options` table in `kardenwort/main.lua` with sensible default values.
- Ensure `mp.options.read_options` only overrides existing keys.
- Prevent script crashes if `mpv.conf` is missing script-specific entries.

## Verification
- Temporarily delete script-opts from `mpv.conf` and verify the script still loads and functions with default values.
- Confirm that malformed `mpv.conf` entries do not prevent the player from starting.

