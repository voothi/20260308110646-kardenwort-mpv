## Context

The current PowerShell-based clipboard setter in `lls_core.lua` introduces ~800ms of latency, which causes synchronization gaps with external AHK observers.

## Goals / Non-Goals

**Goals:**
- Reduce clipboard update latency to <50ms.
- Provide a direct notification path to GoldenDict to bypass polling.

**Non-Goals:**
- Modifying external AHK scripts (handled in the `voothi/autohotkey` project).

## Decisions

### 1. Native MPV Clipboard Property
- **Decision**: Use `mp.set_property("clipboard", text)` as the primary method.
- **Rationale**: Direct integration with the OS clipboard via the host application is the most efficient path.

### 2. Explicit Hotkey Trigger
- **Decision**: Add `goldendict_trigger` option to send `^!+n` via PowerShell's `WScript.Shell`.
- **Rationale**: Direct triggering ensures the dictionary popup appears even if the AHK script is lagging or polling is disabled.

## Risks / Trade-offs

- **[Risk] Native Property Availability** → **Mitigation**: Retain PowerShell fallback.
- **[Risk] Shell Overhead for Trigger** → **Mitigation**: The trigger is only sent if `goldendict_trigger=yes`, and it happens *after* the clipboard is already updated.
