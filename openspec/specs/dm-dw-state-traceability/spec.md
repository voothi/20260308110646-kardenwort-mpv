# DM/DW State Traceability

## Purpose
Provide canonical, requirement-level traceability for DM/DW state transitions validated across anchors:
`20260513185445`, `20260513222855`, `20260513223251`, `20260513223949`,
`20260513224230`, `20260513224426`, `20260513224549`, `20260513224804`,
`20260513225010`, `20260513230718`, `20260513231511`, `20260513232211`,
`20260513232755`, `20260513233501`.

## Requirements

### Requirement: Canonical DM/DW State Variables
The project SHALL preserve a canonical state vocabulary for DM/DW interaction.

#### Scenario: Core state contract
- **WHEN** DM/DW behavior is documented or validated
- **THEN** state semantics SHALL reference:
- `DW_FOLLOW_PLAYER` (white-line follow-leading gate),
- `DW_ACTIVE_LINE` (current playback subtitle index),
- `DW_CURSOR_LINE` (standing yellow line context),
- `DW_CURSOR_WORD` (yellow pointer token; `-1` means no active pointer),
- `DW_ANCHOR_LINE` and `DW_ANCHOR_WORD` (range anchor),
- `DW_VIEW_CENTER` (manual/book viewport center),
- `DW_SEEKING_MANUALLY` and `DW_SEEK_TARGET` (manual seek transit state).

### Requirement: Esc Stage 3 Post-Conditions
Final `Esc` clear MUST establish a deterministic follow-ready state in both DM and DW.

#### Scenario: Final staged clear
- **WHEN** Esc reaches Stage 3 (final yellow pointer clear)
- **THEN** `DW_CURSOR_WORD` SHALL be `-1`
- **AND** `DW_CURSOR_LINE` SHALL be synchronized to the active playback line resolved from live `time-pos` at Esc time
- **AND** `DW_FOLLOW_PLAYER` SHALL be `true`
- **AND** manual seek transit markers SHALL be cleared (`DW_SEEKING_MANUALLY = false`, `DW_SEEK_TARGET = -1`).

### Requirement: Null-Pointer Activation Source
After pointer clear, first activation MUST resolve from current runtime context, not stale history.

#### Scenario: First activation after final Esc
- **WHEN** pointer state is null (`DW_CURSOR_WORD = -1`) and user activates navigation
- **THEN** source line resolution SHALL prioritize:
1. valid standing `DW_CURSOR_LINE`,
2. otherwise active `DW_ACTIVE_LINE`.
- **AND** `UP`/`DOWN` SHALL use directional visual-line entry semantics
- **AND** `LEFT`/`RIGHT` SHALL use line-edge token entry semantics.

### Requirement: Seek/Scroll Null-Source Synchronization
Manual `a`/`d` seek and explicit viewport scroll MUST keep null-pointer source state synchronized.

#### Scenario: Post-seek synchronization
- **WHEN** pointer is null and user performs manual `a`/`d` seek
- **THEN** standing source line for next pointer activation SHALL synchronize to seek target context.

#### Scenario: Post-scroll synchronization
- **WHEN** pointer is null and user performs explicit manual viewport scrolling
- **THEN** standing source line for next pointer activation SHALL synchronize to viewport-center context.

### Requirement: Book Mode Parity Between DW and DM
Book Mode paging semantics MUST be behaviorally equivalent in DW and DM mini viewport workflows.

#### Scenario: Playback paging parity
- **WHEN** Book Mode is ON and playback advances
- **THEN** DW (`W`) and DM mini (`C` with `W` closed) SHALL apply equivalent paged follow behavior.

#### Scenario: Enabling Book Mode while DM is active
- **WHEN** DM is active and DW is closed
- **AND** Book Mode is enabled
- **THEN** workflow SHALL remain in DM (no forced mode jump to DW)
- **AND** DM SHALL adopt DW-equivalent Book paging semantics.

### Requirement: Cross-Spec Traceability Mapping
DM/DW traceability SHALL map resolved behavior to governing specs.

#### Scenario: Traceability cross-reference
- **WHEN** this traceability spec is reviewed
- **THEN** behavior SHALL be traceable to:
- `openspec/specs/drum-window/spec.md` (Esc staging and cross-mode synchronization),
- `openspec/specs/drum-window-navigation/spec.md` (null-selection activation and seek/scroll source rules),
- `openspec/specs/book-mode-navigation/spec.md` (Book Mode DM/DW parity).

### Requirement: Acceptance Regression Checklist
The traceability spec SHALL provide executable validation intent for non-regression checks.

#### Scenario: Validation workflow
- **WHEN** validating DM/DW state behavior
- **THEN** the checklist SHALL include:
1. staged `Esc` clear restoring follow-leading in DM and DW,
2. `a`/`d` then `Esc` then arrow activation from current white context,
3. null-pointer scroll then arrow activation from current viewport context,
4. Book Mode enable in DM without forced DW switch and with paged follow parity,
5. repeat checks with Book Mode OFF and ON.
