## Context

The Drum Window (introduced in v1.2.16) repurposes the `LEFT`/`RIGHT`/`UP`/`DOWN` keys for text-editor style navigation. This created a scenario where users could not perform the standard 2-second seek without closing the window, breaking the immersion flow.

## Goals / Non-Goals

**Goals:**
- Provide a dedicated, modifier-based seek path.
- Support English and Russian layouts for the new seek keys.
- Ensure the new keys use "exact" seeking for precise alignment.

## Decisions

- **Hotkey Selection**: `Shift+A` (backward) and `Shift+D` (forward) were chosen to avoid conflicts with common mpv defaults and to provide a natural hand position for seeking.
- **Mapping Specifications**:
    - `A` / `Ф` mapped to `seek -2 exact`.
    - `D` / `В` mapped to `seek 2 exact`.
- **Scope**: These bindings are added to the global `input.conf` rather than being script-injected, following the "Source of Truth" principle established in v1.2.6.

## Risks / Trade-offs

- **Risk**: Key conflict with other script-based tools.
- **Mitigation**: The chosen keys are specifically mapped to `exact` seeking, which is the primary navigation requirement for this suite, and are clearly documented in the README.
