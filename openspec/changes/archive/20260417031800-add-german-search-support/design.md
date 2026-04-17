## Context

The search system in `lls_core.lua` relies on a whitelist-based input grabber. When search mode is enabled, the script iterates through a `chars` string and creates a forced key binding for every character. Currently, this string lacks German-specific characters, causing them to be ignored by the search input buffer.

## Goals / Non-Goals

**Goals:**
- Enable typing of German umlauts (`ä`, `ö`, `ü`, `Ä`, `Ö`, `Ü`) and the eszett (`ß`, `ẞ`) in the search field.
- Ensure the character whitelist remains compatible with the existing UTF-8 iteration and binding logic.

**Non-Goals:**
- Modification of the search result sorting or highlighting logic (which already supports these characters).
- Implementation of an IME (Input Method Editor) or complex text input system.

## Decisions

- **Whitelist Extension**: We will append `äöüßÄÖÜẞ` to the `chars` variable in `manage_search_bindings`.
- **UTF-8 Iterator Reuse**: The existing `utf8_iter` function correctly handles correctly formatted multi-byte UTF-8 sequences, so no changes to the iteration or binding function are required. 
- **Key Binding Reliability**: MPV's `add_forced_key_binding` accepts UTF-8 character strings as key names, which will trigger correctly when those characters are produced by the keyboard.

## Risks / Trade-offs

- **Z-Index/Binding Conflicts**: Adding more bindings slightly increases the chance of conflicts with other script-level bindings, though `add_forced_key_binding` safely overrides them during the active search session.
- **Capital Eszett (ẞ)**: While rare, it is included for completeness and consistency with the lowercase version.
