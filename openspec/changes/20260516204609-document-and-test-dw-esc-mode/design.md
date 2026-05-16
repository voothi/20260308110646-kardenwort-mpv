## Context
The `DW Esc Mode` feature was introduced to provide users with granular control over the Drum Window's behavior when exiting or escaping. Specifically, it addresses how the navigation focus (current subtitle vs. last selection) is handled. While the core logic is implemented in `scripts/kardenwort/main.lua`, it needs a structured design for testing and verification.

## Goals / Non-Goals

**Goals:**
- Provide a clear mapping of `DW Esc Mode` states to expected behaviors.
- Implement an OSD-based feedback system that confirms state changes with professional labels.
- Design an "omnidirectional" test suite that validates mode cycling, OSD correctness, and state retention.

**Non-Goals:**
- Modifying the core Drum Window rendering engine.
- Adding complex multi-key macro sequences beyond basic cycling.

## Decisions

**1. Mode Cycling Logic:**
The modes will be organized in a circular order: `auto_follow_current` -> `neutral_last_selection` -> `neutral_current_subtitle`. This ensures a predictable UX.

**2. Externalized Labels:**
OSD labels are decoupled from internal identifiers (e.g., `auto_follow_current` -> `AUTO FOLLOW CURRENT`) to maintain a clean UI/UX and allow for future localization.

**3. Test Strategy:**
Use the existing Python-based acceptance test framework to:
- Simulate key presses (`n` / `т`).
- Verify OSD messages using the `osd-msg` property.
- Verify internal `Options` state changes.

## Risks / Trade-offs

- **OSD Clutter**: Repeated cycling might lead to OSD fatigue; however, the clear labels mitigate confusion.
- **State Complexity**: Adding more modes increases the state space for navigation, requiring robust "omnidirectional" testing to prevent edge-case regressions.
