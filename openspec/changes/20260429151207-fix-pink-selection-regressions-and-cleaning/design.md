## Context

The current `ctrl_commit_set` function in `lls_core.lua` handles the export of paired (Pink) selections. Unlike the `dw_anki_export_selection` function used for contiguous (Yellow) selections, it lacks a formal cleaning pass for the `term` string and uses a simplified, hardcoded trailing punctuation restoration that doesn't respect the actual subtitle content or handle metadata interference correctly.

## Goals / Non-Goals

**Goals:**
- Unify the term cleaning logic between Yellow and Pink selection paths.
- Restore literal trailing punctuation for Pink selections.
- Fix metadata "blocking" of sentence boundary detection in the export loop.
- Ensure proper spacing between contiguous words in the `term` using `compose_term_smart`.

**Non-Goals:**
- Changes to the tokenizer logic itself (fixing the greediness of brackets). This will be handled by ensuring the cleaning logic correctly strips metadata tokens regardless of how they were tokenized.
- Changing the OSD rendering of Pink selections.

## Decisions

### 1. Unified Cleaning Function
We will extract the term cleaning logic from `dw_anki_export_selection` into a shared helper function `clean_anki_term(term)` or similar. This function will handle:
- ASS tag removal (`{...}`)
- Balanced bracket stripping (`[...]`)
- Whitespace normalization
- Leading/trailing punctuation trimming

### 2. Multi-Pass Punctuation Restoration
The Pink export loop will be updated to perform a multi-pass lookahead:
- **Pass 1**: Find the selected word token.
- **Pass 2**: Iterate through subsequent tokens. If a token is a metadata tag (per `Options.anki_strip_metadata`), skip it.
- **Pass 3**: If a punctuation token (non-word) is found, capture its literal text (e.g., `!`, `?`, `...`) and set `raw_had_terminal`.
- **Pass 4**: Stop when a word token (non-metadata) is encountered.

### 3. Joiner Parity
`ctrl_commit_set` will be refactored to use `compose_term_smart` when building the `term` string for non-gap segments. This ensures that adjacent tokens like `Paketsortierung` and `[UMGEBUNG]` are joined with a space if appropriate, rather than being welded together.

## Risks / Trade-offs

- **Redundancy**: Shared cleaning might require careful handling of `raw_had_terminal` since punctuation is both used for restoration and trimmed during cleaning.
- **Complexity**: The lookahead in `ctrl_commit_set` adds another nested loop, but since subtitle lines are typically short, the performance impact is negligible.
