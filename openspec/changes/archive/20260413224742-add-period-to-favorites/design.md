## Context

The export system in `lls_core.lua` performs a "clean capture" of the selected term (the `source_word` field). This cleanup step removes all leading and trailing punctuation to avoid junk characters if a user includes a comma or extra space in their selection. However, for full-sentence exports, this aggressively removes important terminal punctuation (Periods, Question Marks, Exclamation Points).

## Goals / Non-Goals

**Goals:**
- Detect if the original source text for a `term` ended with terminal punctuation.
- Automatically restore a period to exported terms if they are capitalized and lost their original terminal punctuation during cleaning.
- Ensure `source_word` and `source_sentence` (context) fields both maintain grammatical consistency.

**Non-Goals:**
- Do not add periods to lowercase phrases or single words that didn't have them originally.
- Do not create double punctuation (e.g., `!.`).

## Decisions

- **Raw Terminal Detection**: Captue a boolean state (`raw_had_terminal`) before the punctuation stripping happens in the term cleanup block.
- **Phrase Detection**: Check if the cleaned term contains at least one space (`term:find(" ")`) to distinguish between full sentences/phrases and single words.
- **Boundary Detection**: Analyze the source text immediately preceding the selection to verify if it starts at a sentence boundary (start of subtitle or following `.!?`).
- **Capitalization Guard**: Use the `starts_with_uppercase` helper to ensure we only apply restoration to capitalized sentences/proper thoughts.
- **Restoration Action**: If `is_sentence_boundary` is true, `raw_had_terminal` is true, the term contains a space, and the cleaned term starts with an uppercase letter, append a period.
- **Punctuation Support**: The detection covers `.`, `!`, and `?` while the restoration defaults to `.` for normalized study material.

## Risks / Trade-offs

- [Risk] → **Proper noun periods**. A proper noun at the end of a subtitle might get a period even if it wasn't intended as a full sentence.
- [Mitigation] → This is consistent with the user's preference for clean, study-ready favorites. Proper nouns that are the only element in a subtitle are effectively "the sentence" in that context.
