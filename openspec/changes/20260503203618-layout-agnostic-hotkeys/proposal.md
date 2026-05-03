## Why

The current hotkey and trigger system in Kardenwort-mpv is sensitive to the active keyboard layout, specifically failing for Russian (RU) users. This results in critical failures where configured triggers (e.g., GoldenDict popups) and interactive shortcuts (e.g., copying subtitles) do not respond when the system is set to a non-Latin layout.

## What Changes

- **Layout-Agnostic Triggers**: Expanded the Virtual Key (VK) mapping to include a comprehensive set of alphanumeric and Cyrillic equivalents.
- **Automatic Key Binding Expansion**: Interactive shortcuts bound in the script now automatically register their Russian layout counterparts (e.g., `Shift+e` also binds `Shift+у`).
- **Surgical Shift Normalization**: Automatic binding of both lowercase and uppercase Cyrillic characters when the `Shift` modifier is used, ensuring compatibility across different OS reporting behaviors.
- **Multi-Hotkey Triggering**: The GoldenDict trigger engine now supports and fires multiple space-separated hotkeys from configuration.

## Capabilities

### New Capabilities
- `layout-agnostic-hotkeys`: Specification for the automatic expansion and mapping of keys across different keyboard layouts (English/Russian).

### Modified Capabilities
- `coordinated-input-system`: Requirements for layout-aware input handling and automatic key expansion.
- `unified-clipboard-abstraction`: Requirements for layout-agnostic `key_copy_popup` and `key_copy_main` triggers.

## Impact

- `scripts/lls_core.lua`: Significant update to the binding and trigger logic.
- `mpv.conf`: Simplification of user configuration (no longer need to manually specify dual-layout keys).
