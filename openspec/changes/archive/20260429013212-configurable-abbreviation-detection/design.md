## Context

Abbreviation detection was recently implemented using hardcoded heuristics. While effective for common German patterns, it lacks flexibility for other languages or specific user needs. Exposing this as configuration allows for better long-term maintainability and user control.

## Goals / Non-Goals

**Goals:**
- Enable user-defined abbreviations via config.
- Allow toggling the heuristic "smart" detection.
- Maintain existing detection as defaults.

**Non-Goals:**
- Full regex support in the `anki_abbrev_list` (literal match only).
- Dynamic reloading of the list without script restart (standard script-opts behavior is sufficient).

## Decisions

### Decision 1: Abbreviation List Format

**Choice:** `anki_abbrev_list` as a space-separated string of literal tokens.
**Rationale:** Simple to edit in `mpv.conf` and easy to parse in Lua using `gsub` or a simple loop.

### Decision 2: Smart Detection Toggle

**Choice:** `anki_abbrev_smart = true` by default.
**Rationale:** Preserves the current improved behavior while allowing users to disable it if it causes false negatives in their specific language context.

### Decision 3: Efficient Lookup

Instead of re-parsing the string on every call, `is_abbrev` will check if the word (lowercase) exists within the space-padded list string.

```lua
local list = " " .. Options.anki_abbrev_list:lower() .. " "
if list:find(" " .. w:lower() .. " ", 1, true) then return true end
```

## Risks / Trade-offs

- **[Risk] Case sensitivity** — Mitigation: Normalize both the list and the input word to lowercase for comparison.
- **[Risk] Multiple spaces in config** — Mitigation: Normalize the config string (trim and collapse spaces) during script initialization or during the check.

## Migration Plan

1. Add `anki_abbrev_list` and `anki_abbrev_smart` to the `Options` table in `lls_core.lua`.
2. Update `is_abbrev` to:
   - Normalize word to lowercase.
   - Check against `Options.anki_abbrev_list`.
   - If not found and `Options.anki_abbrev_smart` is true, run heuristic checks.
3. Update `mpv.conf` and `lls.conf`.
