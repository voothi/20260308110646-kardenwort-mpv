## Context

The current `lls_core.lua` script contains multiple ad-hoc implementations for joining subtitle tokens back into natural strings. These implementations are used in:
1.  **On-screen display (`draw_drum`)**: Ad-hoc logic that only handles hyphens and brackets.
2.  **Anki export (`dw_anki_export_selection`)**: Forced space concatenation using `table.concat(words, " ")`.
3.  **Context extraction (`extract_anki_context`)**: Same forced space joiner as Anki export.
4.  **Term composition (`compose_term_smart`)**: A slightly more advanced but incomplete joiner.

The inconsistency leads to broken text where punctuation marks have leading spaces (e.g., `word ,` instead of `word,`).

## Goals / Non-Goals

**Goals:**
- **Centralize String Reconstruction**: Create a single, robust `compose_term_smart` function.
- **Natural Space Preservation**: Ensure exported context matches the original subtitle's spacing wherever possible.
- **Unicode Punctuation Support**: Correctly handle common punctuation across German, Russian, and English including ellipsis, brackets, and quotes.

**Non-Goals:**
- Retroactive TSV modification.
- Changing the underlying `build_word_list` tokenization (which is used for click-testing and highlighting).

## Decisions

- **Decision: Raw Text for Context Building**: In `dw_anki_export_selection` and `ctrl_commit_set`, we will prioritize using the original `subs[k].text` directly. This preserves the exact spacing intended by the subtitle author, rather than trying to perfectly re-emulate it with rules.
- **Decision: Improved Punctuation Rules**: `compose_term_smart` will be updated to include a comprehensive set of "no-space-before" (e.g., `,`, `.`, `!`, `?`, `:`, `;`, `)`, `]`, `}`, `…`, `»`, `”`) and "no-space-after" (e.g., `(`, `[`, `{`, `¿`, `¡`, `«`, `“`) rules.
- **Decision: Unified Call Sites**: All ad-hoc joiners in `draw_drum` and `extract_anki_context` will be replaced by calls to the improved `compose_term_smart`.

## Risks / Trade-offs

- **Risk: Disconnected Term Match**: If the user selects non-contiguous words (e.g., words 1 and 3, skipping word 2), `compose_term_smart` is used to build the term. If `extract_anki_context` is given the "raw" context line, it might fail to find the term verbatim if the original text had unusual spacing (e.g., triple spaces) that `compose_term_smart` "normalized".
- **Mitigation**: `extract_anki_context` already has a robust fallback that anchors words individually even if the verbatim match fails.
