## Why

Address "false positive" hotkey triggers where lowercase Russian keys (e.g., `у`) incorrectly invoke Shift-modified functionality (e.g., `Shift+у` or `Shift+e`). This occurs due to mpv's key normalization on Windows, where registering a `Shift+lowercase_cyrillic` binding can inadvertently capture the unshifted lowercase key event.

## What Changes

- **Hardened Expansion Engine**: `expand_ru_keys` now strictly differentiates between explicit shift and implicit shift states.
- **Strict Case Parity**: For Shift-modified English keys, the engine now registers only the uppercase Cyrillic character (e.g., `У`) without the `Shift+` prefix, as this is the canonical form mpv receives on Windows.
- **Diagnostic Tracing**: Implementation of granular logging for key expansion and runtime trigger events to facilitate debugging and ensure binding integrity.
- **Option Sanitization**: Removal of hardcoded Cyrillic duplicates in default option strings, relying entirely on the dynamic expansion engine to prevent configuration-level collisions.

## Capabilities

### Modified Capabilities
- `layout-agnostic-hotkeys`: Refining the registration logic to prevent modifier-normalization collisions on Windows.

## Impact

- `lls_core.lua`: Significant hardening of the `expand_ru_keys` utility and key registration pipeline.
- `mpv.conf`: Minor cleanup of default hotkey assignments.
- Diagnostic logs: Increased visibility into the hotkey subsystem.
