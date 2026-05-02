## Context

The current LLS script uses unstructured `print()` statements for all logging. This results in console spam from periodic background tasks (e.g., TSV sync) and redundant error messages from MPV core (e.g., invalid key names) that are triggered repeatedly. While some silencing was implemented, it was ad-hoc and risked hiding important diagnostics.

## Goals / Non-Goals

**Goals:**
- Provide a unified, level-aware logging interface (`Diagnostic.info`, `Diagnostic.warn`, etc.).
- Allow users to control console verbosity via `mpv.conf`.
- Prevent repetitive log messages through a deduplication mechanism.
- Ensure that "fail-loudly" errors (like config issues) are reported exactly once per session.

**Non-Goals:**
- Replacing MPV's internal logging system (only wrapping it for the script).
- Implementing a persistent log file on disk (rely on MPV's console/terminal).

## Decisions

1.  **Deduplication Strategy**: Use a session-level "seen" map for messages. For periodic tasks, use a time-based bucket (e.g., don't log the same successful sync more than once every 5 minutes).
2.  **Log Level Default**: Default to `info`. Periodic success messages will be mapped to `debug` or `trace` to remain hidden under normal operation.
3.  **Config Validation**: Consolidate keybinding validation into a single `validate_bindings()` function called during startup. This function will report all issues in a single summary block.
4.  **mp.msg Integration**: map `Diagnostic` levels to `mp.msg` levels:
    - `error` -> `mp.msg.error`
    - `warn`  -> `mp.msg.warn`
    - `info`  -> `mp.msg.info`
    - `debug` -> `mp.msg.verbose`
    - `trace` -> `mp.msg.debug`

5.  **Early Startup Robustness**: To ensure logging is available from the first line of execution:
    - The `Options` table is forward-declared at the script head to prevent scope errors in diagnostic closures.
    - `Diagnostic.log` implements a safety fallback: if `Options` is not yet initialized, the system defaults to `info` verbosity.
6.  **Config Cleanup Strategy**: The health check identified existing multicharacter Cyrillic aliases (e.g., `ЛЕВЫЙ`) as invalid key names. Decisions:
    - Purge these invalid aliases from both script defaults and `mpv.conf`.
    - Retain single-character layout-switching keys (e.g., `п`, `а`) as they are valid MPV key names.
7.  **Lifecycle Noise Reduction**: Demote routine transitions (e.g., `OPENING/CLOSING DRUM WINDOW`) from `info` to `debug` level to ensure a truly silent startup for the user.
8.  **Layout-Agnostic Diagnostics**: Bind `ё` (Cyrillic layout equivalent of backtick) to `console/enable` to ensure users can access the debug console regardless of their active keyboard layout.

## Risks / Trade-offs

- **Risk**: Over-deduplication might hide legitimate recurring issues (e.g., intermittent file access errors).
- **Mitigation**: Errors and Warnings will have a longer deduplication TTL (or no TTL, just once per session) while purely informational logs will have a shorter one.
