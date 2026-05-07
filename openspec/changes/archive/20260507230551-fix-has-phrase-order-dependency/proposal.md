## Why

The `has_phrase` flag inside `calculate_highlight_stack` was unconditionally overwritten on every matched term (line 2296 of `scripts/lls_core.lua`):

```lua
has_phrase = (#term_clean > 1)   -- last match wins
```

This means the last TSV record processed in the candidate loop determined whether full or surgical backlight was applied to a word — making the visual output dependent on TSV row order rather than on the semantic content of the match set. Concretely: if a multi-word phrase record ("Geld und die Zeit") happened to be followed in the TSV by single-word records ("Zeit", "Geld"), those single-word matches would reset `has_phrase` to `false`, stripping the word of its "full phrase" backlight style even though a matching phrase term exists.

## What Changes

- `has_phrase` in `calculate_highlight_stack` becomes a monotone accumulator: once any matched term is a multi-word phrase, the flag stays `true` for the remainder of the word's evaluation, regardless of subsequent single-word matches.
- No user-facing configuration or API changes.

## Capabilities

### New Capabilities
- none

### Modified Capabilities
- anki-highlighting: The `has_phrase` derivation rule is updated — it now reflects whether ANY matched term for the current word is multi-word, not just the last one. The spec scenario "full highlighting for phrases" becomes order-independent.

## Impact

- `scripts/lls_core.lua`: Single one-character change on line 2296 (`=` → `= has_phrase or`).
- Performance: Zero — the change is a boolean short-circuit.
- Configuration: None required.
