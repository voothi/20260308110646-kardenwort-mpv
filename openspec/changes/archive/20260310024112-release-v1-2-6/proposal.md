## Why

This change formalizes the Keybinding Source of Truth Consolidation introduced in Release v1.2.6. Prior to this, the `"c"` key for Drum Mode was hardcoded within the script logic, creating potential conflicts and diverging from the project's goal of centralizing all keyboard shortcuts in `input.conf`. This consolidation ensures that configuration is handled in one place, improving maintainability.

## What Changes

- Removal of the hardcoded `"c"` default key for the `toggle-drum-mode` command in `scripts/lls_core.lua`.
- Conversion of all 11 script-defined keybindings to use `nil` as the default key, purely exposing named command handlers.
- Repository cleanup: Removal of the obsolete standalone script `scripts/old_copy_sub.lua`.
- Update to `.gitignore` to include `__pycache__/` for Python environment cleanliness.

## Capabilities

### New Capabilities
- `keybinding-consolidation`: A configuration strategy that enforces `input.conf` as the exclusive authority for physical key mappings.
- `repo-cleanup`: Standard maintenance practices for removing legacy code and ignoring build artifacts.

### Modified Capabilities
- None (Maintenance and configuration normalization).

## Impact

- **Configuration Integrity**: No hidden or hardcoded keys in the script logic.
- **Ease of Customization**: Users can rebind all features exclusively through `input.conf` without script modifications.
- **Repository Health**: Reduced clutter from obsolete files and temporary build artifacts.
