## Context

The previous keybinding system required multiple `Ctrl` modifiers which slowed down the workflow. Furthermore, `input.conf` was a flat list of commands without grouping or explanation, making it difficult for the user to understand the nuances of the "Smart Spacebar" or specific Drum Mode toggles.

## Goals / Non-Goals

**Goals:**
- Transition to single-key study shortcuts.
- Support dual-layout (EN/RU) without requiring manual language switching.
- Transform `input.conf` into a readable instruction manual.

## Decisions

- **Modifier Removal**: `Ctrl+X` and `Ctrl+Z` are replaced by `x` and `z`. Capitalized variants (`X`, `Z`) are mapped to the same commands to handle `Shift` or `Caps Lock`.
- **Layout Aliasing**: Russian characters `ч` (for `x`) and `я` (for `z`) are explicitly mapped in `input.conf`.
- **Structural Grouping**: `input.conf` is divided into three sections:
    1. **Navigation & System**: Core mpv movement and OSC toggles.
    2. **Language Layouts**: Secondary subtitle and SID management.
    3. **Feature Toggles**: Drum Mode, Context Copy, and Autopause.
- **Inline Docs**: Each binding is preceded by a `#` comment explaining its behavior (e.g., explaining why `LEFT` is fixed at 2 seconds).

## Risks / Trade-offs

- **Risk**: Key conflicts with default mpv commands.
- **Mitigation**: Keys like `x` and `z` are traditionally less critical or are repurposed within this specialized suite to prioritize study efficiency.
