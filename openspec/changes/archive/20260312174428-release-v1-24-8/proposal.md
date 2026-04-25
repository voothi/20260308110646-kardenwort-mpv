## Why

This change formalizes the Stability & Search Selection features introduced in Release v1.24.8. Initial user feedback indicated that the subtitle search was too restrictive, leading to the development of a "really fuzzy" non-contiguous character algorithm. Additionally, several critical stability regressions related to Lua's lexical scoping and UI layering were identified and resolved to ensure the suite's robustness during intensive immersion sessions.

## What Changes

- Implementation of a **"Really" Fuzzy Search** algorithm: Replacing literal substring matching with a character-order algorithm that supports non-contiguous matching (e.g., "hl wrd" matches "hello world").
- Enforcement of **UI Layering (Z-Index)**: Explicitly initializing OSD overlays with Z-values to prevent visual clashing: Search HUD (30) > Drum Window (20) > Drum Mode (10).
- Hardening of **Lexical Scope Stability**: Relocating all command functions to the top-level section of `lls_core.lua` to ensure they are defined before their respective keybinding calls.
- Refinement of **Precision Timing**: Updating `parse_time` to correctly handle 2-digit centisecond fields common in ASS subtitle formats, fixing desynchronization issues.
- Integration of specialized fixes for visibility persistence, Ctrl+A (Select All) functionality, and typing-related script crashes.

## Capabilities

### New Capabilities
- `fuzzy-search-optimization`: An advanced string-matching capability that improves the speed and flexibility of vocabulary lookup.
- `osd-layer-management`: A systematic approach to managing the visual priority of multiple overlapping UI elements.
- `script-stability-hardening`: Structural code patterns that eliminate runtime crashes and race conditions related to scope and timing.

### Modified Capabilities
- `universal-subtitle-search`: Upgraded with superior matching logic and stability.

## Impact

- **Search Fluidity**: Significantly faster lookup of phrases even with incomplete or approximate queries.
- **Visual Predictability**: Elimination of "disappearing window" bugs and UI rendering priority conflicts.
- **Data Integrity**: Accurate subtitle synchronization across both SRT (millisecond) and ASS (centisecond) formats.
