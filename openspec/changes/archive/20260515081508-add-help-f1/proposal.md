# Proposal: Unified Help HUD (F1)

## Problem Statement
Kardenwort has a rich set of immersion-centric features and keybindings, but users currently rely on the `README.md` or `input.conf` to discover them. As the suite evolves and users customize their own `mpv.conf`, static documentation becomes outdated. There is no in-player discovery mechanism for the current, active shortcut set.

## Proposed Solution
Implement a **Unified Help HUD** triggered by the **F1** key. This HUD will:
1.  **Dynamic Discovery**: Dynamically parse the active keybindings (including remapped `kardenwort-` options from `mpv.conf`) to show the *actual* keys in use.
2.  **Premium Aesthetic**: Use a high-performance OSD overlay with a dark, semi-transparent background (matching Drum Mode/Search HUD) and a clean, tabular layout.
3.  **Categorized View**: Group shortcuts by functional modules (AutoPause, Drum Mode, Reading Mode, Anki Mining).
4.  **Hardware-Agnostic**: Display both English and Russian layout counterparts where applicable.

## Goals
- Provide zero-latency access to the full command reference.
- Ensure the help screen reflects user-customized bindings from `mpv.conf`.
- Maintain visual consistency with the Kardenwort design system.

## Non-Goals
- Replacing `README.md` for deep documentation.
- Allowing interactive key remapping through the UI (remains in `mpv.conf`).
