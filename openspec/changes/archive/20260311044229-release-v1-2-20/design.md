## Context

The v1.2.18 release involved adding almost 400 lines of code to the core `lls_core.lua` file. Given the complexity of the new layout engine and mouse handlers, a formal audit was required to guarantee that no "ghost regressions" were introduced in the existing `repeatable` logic or FSM transitions.

## Goals / Non-Goals

**Goals:**
- Verify that all changes in the `abf23f4` → `27c1e76` range are regression-free.
- Sync all documentation (README, Release Notes) with the v1.2.18 feature set.
- Formalize the v1.2.18 technical narrative.

## Decisions

- **Hunk-Level Audit**: The audit is broken down into 10 distinct hunks (Options, FSM, Layout, Render, Mouse Handlers, etc.). Each is verified to ensure it doesn't touch existing core functions like `cmd_dw_copy` or `master_tick`.
- **Identity Sync**: The README is updated to promote the Drum Window as a "Static Reading Mode" with "Actionable Text," aligning with the v1.2.14 terminology standardization.
- **Keybinding Visibility**: `MBTN_LEFT (Drag)`, `MBTN_LEFT (Double)`, and `Ctrl+UP/DN` are added to the README to ensure visibility of these "hidden" mouse interactions.

## Risks / Trade-offs

- **Risk**: Overlooking a subtle logical regression despite the audit.
- **Mitigation**: The audit specifically lists "Functions Verified Completely Untouched" (e.g., `cmd_toggle_drum`, `tick_autopause`) to define the boundary of the change.
