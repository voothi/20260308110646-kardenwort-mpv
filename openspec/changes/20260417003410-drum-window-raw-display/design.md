## Context

The current `build_word_list` scanner (implemented in ZID 20260417000743) skips all whitespace characters:
```lua
elseif c:match("^%s$") then
    i = i + 1
```
This forces `compose_term_smart` to dynamically re-insert spaces based on a "Best Guess" set of rules (e.g., "no space after a hyphen"). While this produces clean output for many cases, it fails to capture original formatting quirks like `z.B.` or specific comma/spacing combinations preferred by translators.

## Goals / Non-Goals

**Goals:**
- **Exact Mirroring**: Preserve every single character of the original subtitle string in the Drum Window display.
- **Stable Indexing**: Maintain the "Logical Word Index" (where index 1 is the first non-filler word, index 2 is the second, etc.) so that selection ranges and Anki exports remain intuitive.
- **Smart Toggle**: Allow the user to switch back to the "Clean" mode if desired via `dw_original_spacing`.

**Non-Goals:**
- **Dynamic Re-wrapping**: We are not fixing the wrapping logic here, only the character-level formatting.
- **External Dependencies**: Implementation remains pure Lua.

## Decisions

### 1. Full-Stream Tokenization
The scanner loop in `build_word_list` will be updated to push whitespace as a `FILLER` token type instead of increments. However, to minimize breaking existing logic that expects an array of simple strings, we will use a "Dual Token List" or a "Rich Token" structure:
```lua
{ text = "Hello", is_word = true }
{ text = " ", is_word = false }
```

### 2. Logic-Visual Mapping
Selection and highlighting logic will be updated to only "count" tokens where `is_word` is true. `FSM.DW_CURSOR_WORD` will remain an index into the "visible" words. A lookup function will map this logical index to the absolute token index for rendering.

### 3. Joiner Normalization
When `dw_original_spacing` is enabled, the joining logic will simply concatenate all tokens in the stream. This guarantees bit-perfect reproduction of the original subtitle line.

## Risks / Trade-offs

- **Memory**: Slightly higher memory usage per subtitle line due to table-based tokens (instead of strings).
- **Selection Hit-testing**: The logic for resolving screen coordinates to word indices must skip whitespace tokens.
