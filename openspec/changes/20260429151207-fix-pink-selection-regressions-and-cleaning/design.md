## Context

The current `ctrl_commit_set` function in `lls_core.lua` handles the export of paired (Pink) selections. Unlike the `dw_anki_export_selection` function used for contiguous (Yellow) selections, it lacks a formal cleaning pass for the `term` string and uses a simplified, hardcoded trailing punctuation restoration that doesn't respect the actual subtitle content or handle metadata interference correctly.

## Goals / Non-Goals

**Goals:**
- Unify the term cleaning logic between Yellow and Pink selection paths.
- Restore literal trailing punctuation for Pink selections.
- Fix the "Dangling Parenthesis" regression in Yellow selection by implementing an "End of Line" guard.
- Fix metadata "blocking" of sentence boundary detection in the export loop.
- Ensure proper spacing between contiguous words in the `term` using `compose_term_smart`.

**Non-Goals:**
- Changes to the tokenizer logic itself.
- Changing the OSD rendering of Pink selections.

## Decisions

### 1. Unified Cleaning Function: `clean_anki_term(term)`
We will extract the term cleaning logic into a shared helper function. This function will handle:
- ASS tag removal (`{...}`)
- Balanced bracket stripping (`[...]`)
- Whitespace normalization
- Leading/trailing punctuation trimming (for non-terminal cases)

### 2. Yellow Selection: End-of-Line Guard
Modify the trailing punctuation capture in `dw_anki_export_selection` to enforce strict boundary conditions:
```lua
if is_last_line and t.logical_idx > p2_w + L_EPSILON then
    -- BREAK if we haven't reached the absolute end of the subtitle segment
    if p2_w < sub.word_count or t.is_word then break end
    -- AVOID capturing opening characters from the next word (e.g. ' (')
    if t.text:match("^[%s%(%[{<]") then break end
end
```
Rationale: This prevents capturing fragments of the next word when the selection ends mid-line.

### 3. Pink Selection: Multi-Pass Punctuation Restoration
The Pink export loop will be updated to perform a multi-pass lookahead:
- **Pass 1**: Find the selected word token.
- **Pass 2**: Iterate through subsequent tokens. If a token is a metadata tag (e.g., `[UMGEBUNG]`), skip it.
- **Pass 3**: If a punctuation token is found, capture its literal text (e.g., `!`, `?`, `...`).
- **Pass 4**: Stop when a "real" word token (non-metadata) is encountered.

### 4. Smart Joiner Integration
`ctrl_commit_set` will be refactored to use `compose_term_smart` when building the `term` string. This ensures consistent spacing and token joining rules across both selection types.

## Risks / Trade-offs

- **Redundancy**: Shared cleaning must be careful not to double-strip punctuation that is intended for restoration.
- **End-of-Line Constraint**: Yellow selection will no longer capture trailing punctuation if the user selects a word in the middle of a line, even if it's the "last word" of a phrase. This is a trade-off for correctness against "dangling" characters.
