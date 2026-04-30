## Context
The system currently has a mismatch between its documentation (specs) and its core implementation in `scripts/lls_core.lua`. While recent development has moved towards a "Surgical" highlighting model (where only word characters are colored), several specs still mandate "Semantic Punctuation" and "Atomic Brackets." Furthermore, the export logic currently collapses multiple spaces into one, which interferes with the goal of absolute verbatim fidelity.

## Goals / Non-Goals

**Goals:**
- Unify the highlighting and tokenization model to be strictly "Surgical."
- Remove all "Smart" punctuation/bracket logic from the export and highlighting paths.
- Ensure `prepare_export_text` and `clean_anki_term` preserve all whitespace and non-metadata brackets.

**Non-Goals:**
- Changing the underlying tokenizer (`build_word_list_internal`) except to ensure it remains word-based.
- Modifying OSD rendering typography (which still needs "Smart" spacing for visual legibility).

## Decisions

### 1. Removing Space Normalization in Export
The `gsub("%s+", " ")` call will be removed from `clean_anki_term` and `prepare_export_text`. 
- **Rationale**: Direct adherence to the "Verbatim" requirement (Req 112). Multiple spaces in the source SRT must be preserved in the exported TSV/Clipboard.

### 2. Spec Alignment: Deprecating Semantic Punctuation
Requirements 103 (Semantic Punctuation) and 114 (Atomic Tokens) in `anki-highlighting` will be removed or marked as deprecated. 
- **Rationale**: Simplification and elimination of visual ambiguity. Highlighting will strictly apply to tokens where `t.is_word` is true.

### 3. Maintaining Surgical Highlighting
The early-exit in `calculate_highlight_stack` for non-word tokens will be formally documented as the standard behavior. This ensures that brackets like `[` or `(` remain the default OSD color even if the enclosed word is highlighted.

## Risks / Trade-offs

- **Risk**: Some older exported cards might have used the "normalized" space model, but since we are moving towards verbatim, the impact on new mining is positive.
- **Trade-off**: Brackets and punctuation will never be colored by database matches, which some users might find less "integrated," but it provides a much cleaner and more predictable visual interface.
