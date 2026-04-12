## Context

The system recently moved to an adaptive highlighting model where punctuation is colored for phrases but not for single words. However, the export engine and the multi-match detection logic (where a word card exists inside a phrase card) were not fully hardened, leading to punctuation "leakage" into Anki and visual inconsistencies.

## Goals / Non-Goals

**Goals:**
- Ensure `MBTN_MID` (Middle Click) exports are always clean of boundary punctuation.
- Ensure visual highlights remain "Flow-oriented" (colored punctuation) if any match for a word is a phrase.

**Non-Goals:**
- Removing internal punctuation (e.g., in `im Umbruch. Während`).
- Modifying the Anki TSV structure.

## Decisions

- **Regex-based Sanitization**: Use Lua's `%p` and `%s` classes to strip `^[%p%s]*` and `[%p%s]*$` during the final stage of `cmd_dw_export_anki`.
- **Match-Set Bitwise OR**: In `calculate_highlight_stack`, initialize `has_phrase = false` and use `if #term_words > 1 then has_phrase = true end` inside the loop. Do not return early. This ensures the engine finds the "most complex" match for a word.

## Risks / Trade-offs

- **[Risk]** Stripping too much from acronyms (e.g., `U.S.A.`) -> **[Mitigation]** The regex only targets the extreme starts and ends, so internal dots are safe.
