## Why

Fragmented interaction logic and legacy "discard on release" behavior prevented a smooth mining experience on minimalist controllers (e.g., 8BitDo Zero 2). Users need a persistent, range-aware pairing system that works identically across mouse and keyboard inputs without accidental selection loss.

## What Changes

- **Unified Shortcut Architecture**: Consolidated all mining and selection shortcuts into list-based parameters (e.g., `dw_key_pair`) supporting multiple delimiters.
- **Persistent Interaction Model**: Removed the legacy behavior where releasing the Ctrl key automatically cleared the pending paired selection (Pink).
- **Synchronized Cursor Jumps**: Explicitly forced the Drum Window cursor (Yellow) and anchor to jump to the interaction point for all mouse-triggered actions.
- **Range-Aware Pairing**: Implemented range-based toggling for the paired selection set, allowing whole yellow selections to be converted to pink via keyboard (`t`) or Ctrl+Drag.
- **Explicit Cleanup**: Added a dedicated `Ctrl+ESC` shortcut to clear the pending paired selection set.

## Capabilities

### New Capabilities
- None

### Modified Capabilities
- `drum-window`: Standardizing functional terminology (e.g., "Paired Selection") and enforcing persistent, range-aware interaction states.
- `anki-export-mapping`: Updating the mining logic to support range-based export triggers from both unified mouse and keyboard inputs.

## Impact

- **lls_core.lua**: Core interaction engine refactored to support list-based bindings and range-aware state transitions.
- **mpv.conf**: Configuration architecture updated to the new list-based parameter format.
- **Documentation**: Specifications updated with functional color clarifiers to bridge visual representation and internal logic.
