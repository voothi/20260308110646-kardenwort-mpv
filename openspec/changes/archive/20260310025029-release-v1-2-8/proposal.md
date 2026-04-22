## Why

This change formalizes the Hotkey Simplification & Documentation introduced in Release v1.2.8. The previous modifier-heavy shortcuts (`Ctrl+X`, `Ctrl+Z`) were identified as friction points for rapid language study. Additionally, the lack of structured documentation in `input.conf` hindered feature discoverability. This update focuses on ergonomic improvements and configuration clarity.

## What Changes

- Simplification of core study hotkeys: `toggle-copy-context` moved from `Ctrl+X` to `x`/`X`, and `cycle-copy-mode` moved from `Ctrl+Z` to `z`/`Z`.
- Implementation of cross-layout symmetry by adding Russian layout counterparts (`ч`, `Я`) to ensure functionality across different system languages.
- Complete reorganization of `input.conf` into functional groups: Navigation & System, Language Layouts, and Feature Toggles.
- Addition of descriptive inline comments for every keybinding to explain the "what" and "why" behind specific behaviors.

## Capabilities

### New Capabilities
- `hotkey-simplification`: A design strategy prioritizing single-key, modifier-free shortcuts for frequently used study actions.
- `config-documentation`: A standard for self-documenting configuration files that provide inline context for all user-facing controls.

### Modified Capabilities
- None (User experience and configuration enhancement).

## Impact

- **Ergonomics**: Reduced physical strain and increased speed during study sessions through simplified keypresses.
- **Accessibility**: Seamless operation across English and Russian keyboard layouts.
- **Maintainability**: A structured and commented `input.conf` that is easier to manage and customize.
