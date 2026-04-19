## Why

To support minimalist hardware like the 8BitDo Zero 2 remote control, the Drum Window's word selection and mining mechanism must be unified. Previously, paired (non-contiguous) word addition was tied to a specific color (pink) and required the Ctrl key, creating cognitive friction and hardware limitations. This change unifies these actions into context-aware "smart" triggers that work seamlessly across mouse and keyboard inputs.

## What Changes

- **Smart Export Mechanism**: Refactored the Middle-Mouse Button (MMB) and its keyboard equivalents to automatically detect the selection context. Clicking a "paired" (pink) word now commits the entire set without requiring the Ctrl key.
- **Unified Shortcut Schema**: Replaced disparate configuration parameters with a coordinated `dw_key_...` naming system.
- **Multi-Delimiter Input Lists**: Implemented support for space, comma, or semicolon separated lists for all Drum Window shortcuts, allowing users to map multiple keys (EN, RU, Mouse) to a single action in one parameter.
- **Explicit Interaction Mapping**: Moved all hardcoded modifier shortcuts (like Ctrl + MMB) into the configuration file to ensure full user control.

## Capabilities

### New Capabilities
- `coordinated-input-system`: Implements a multi-delimiter list parser and unified naming scheme for all Drum Window interaction triggers.

### Modified Capabilities
- `drum-window`: Refines the "Miner" interaction model to support context-aware addition (smart yellow/pink logic).
- `anki-export-mapping`: Updates the mapping of physical inputs to mining actions to support unified lists.
- `lls-mouse-input`: Unifies mouse button behavior with keyboard shortcuts to provide parity for remote control users.
- `mmb-drag-export`: Enhances the drag-export logic to gracefully handle paired selection contexts.

## Impact

- **Affected Code**: `scripts/lls_core.lua` (binding logic and export callbacks).
- **Configuration**: `mpv.conf` (renamed parameters, updated format to space-separated lists).
- **Documentation**: `input.conf` (updated internal shortcut descriptions).
