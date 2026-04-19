# Proposal: Finalize Interaction Hardening

## Objective
Finalize the Drum Window (Mode W) interaction model by resolving regressions in mouse/keyboard behavior and hardening the interface against hardware-induced jitter and environment-specific constraints.

## Problem Statement
Recent updates to the unified mouse handler introduced a "Focus Regression" where Right Mouse Button (RMB) tooltips incorrectly triggered the yellow selection cursor, violating the informational-only specification for action triggers. Additionally, the window failed to open for internal/embedded subtitles in MKV files due to a strict file-path check, and users on remotes/touchpads experienced "ghost clicks" where the mouse would clear keyboard focus immediately after navigation.

## Proposed Changes
1.  **Interaction Isolation**: Hardening the `make_mouse_handler` factory to strictly distinguish between "Selection" (Focus-moving) and "Action" (Informational/Toggle) interactions via the `updates_selection` flag.
2.  **RMB Resilience**: Restore the v1.42.4 behavior where RMB exclusively pins tooltips without altering the selection cursor range.
3.  **Global Mouse Shield**: Implement a smart 150ms lockout (`nav` wrapper) for all navigation and keyboard actions to suppress hardware jitter, while ensuring modifier keys (Ctrl, Shift, Alt, Meta) remain responsive for immediate mouse-keyboard combinations.
4.  **Embedded Stream Support**: Relax the initialization check to allow Mode W to open if subtitles are loaded in memory, even if no external file path exists.

## Success Criteria
- RMB pins tooltips without moving the yellow highlight or starting a drag selection.
- Mode W opens correctly for embedded MKV subtitle tracks.
- "Meta/Ctrl/Shift + Click" combinations remain responsive.
- Navigating with a remote control does not lead to accidental focus loss from mouse drift.
