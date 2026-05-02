## Why

The current logging system uses simple `print()` calls which lack granularity and lead to "console spam" during periodic operations (like the 10-second TSV sync). Furthermore, some configuration errors (like invalid key names) are reported as cryptic MPV core errors repeatedly, while others are silenced entirely to avoid spam. This "all or nothing" approach worsens the debugging experience and hides potential issues, violating the principle of "fail loudly but only once".

## What Changes

1.  **Unified Diagnostic Engine**: Replace ad-hoc `print()` calls with a centralized logging wrapper using `mp.msg` for proper log-level support.
2.  **Granular Log Levels**: Introduce standard levels (`error`, `warn`, `info`, `debug`, `trace`) allowing the user to filter logs via configuration.
3.  **Log Deduplication**: Implement a mechanism to suppress identical messages (e.g., repeating "Unknown key" or "TSV Loaded") within a session or time window.
4.  **Startup Health Check**: A centralized validation pass during script initialization that checks for common configuration errors (invalid paths, malformed keybindings, missing dependencies) and reports them in a structured summary.
5.  **Context-Aware Logging**: Silence periodic background tasks (like syncs) by default, while ensuring they log errors or "payload discovery" (new highlights) at the standard `info` level.

## Capabilities

### New Capabilities
- `smart-diagnostics`: A unified console logging and startup validation system.

### Modified Capabilities
- `ui-noise-reduction`: Expanded to include console log suppression for periodic tasks and redundant status updates.

## Impact
- `lls_core.lua`: Refactoring of all logging and initialization validation logic.
- `mpv.conf`: Introduction of the `lls-log_level` parameter.
- Developer Experience: High-fidelity diagnostics without console clutter.
