## Context

Subtitle files (especially `.ass` formats) frequently bundle multiple translations. When these are imported into the reading mode, the presence of Cyrillic characters in the primary track can be distracting for users focusing on English. Furthermore, as the UI becomes more refined, explicit status messages for obvious visual states (like a window being open) become redundant "noise."

## Goals / Non-Goals

**Goals:**
- Filter out Cyrillic lines from the primary subtitle import.
- Remove redundant "OPEN/CLOSED" OSD messages.
- Harden the script against nil-pointer exceptions in text processing.

## Decisions

- **Scope Hoisting**: Functions like `has_cyrillic` are moved to the top of `lls_core.lua`. This follows the "Pre-Binding Function Availability" principle from v1.24.8, ensuring they are globally available for all parsing logic.
- **Parsing Guard**: A conditional check is added to the `Dialogue:` pattern matcher in the `.ass` loader. If `has_cyrillic(text)` is true, the line is skipped for the primary track collection.
- **Nil Defense**: Standard Lua guards (`if not str then return false end`) are added to the start of all text-utility functions. This provides defense-in-depth against empty strings or unexpected data types from the media engine.
- **Silence by Default**: The OSD messages in `cmd_toggle_drum_window` are commented out. The visual appearance of the parchment background is considered sufficient feedback for the toggle state.

## Risks / Trade-offs

- **Risk**: A legitimate target-language line might contain a Cyrillic character (e.g., a proper noun) and be filtered out.
- **Mitigation**: This logic is primarily targeted at translation tracks. In the event of over-filtering, the user can still access all tracks via standard mpv track switching.
