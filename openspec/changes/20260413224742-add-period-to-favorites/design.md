## Context

The `extract_anki_context` function in `lls_core.lua` identifies sentence boundaries by searching for punctuation markers (`.!?`) around a selected term. However, the current implementation strips leading and trailing punctuation characters to clean up the result. While this ensures no duplicate punctuation if the user's selection was messy, it often leaves complete sentences without their final period.

## Goals / Non-Goals

**Goals:**
- Automatically append a period to exported sentences that start with a capital letter and follow a known sentence boundary.
- Preserve existing terminal punctuation if present.
- Ensure the rule only applies when the exported text begins a "new thought" (capitalized).

**Non-Goals:**
- Do not add periods to sentence fragments (lowercase starts).
- Do not add multiple periods (avoid `..`).

## Decisions

- **Detection via Capitalization**: The primary trigger for adding a period will be checking if the extracted sentence starts with an uppercase character (A-Z or Unicode uppercase).
- **Contextual Awareness**: We will check if the sentence extraction started at the beginning of the file/block or immediately after a punctuation marker.
- **Punctuation Enforcement**: If the capitalization rule is met and the sentence does not end in `.` `!` or `?`, a `.` will be appended.
- **Implementation Point**: The logic will be added to `extract_anki_context` after the boundary extraction but before returning the final string.

## Risks / Trade-offs

- [Risk] → **False positives on proper nouns**. If a user selects just a proper noun (e.g., "Germany") that follows a period, it might get a period ("Germany."). 
- [Mitigation] → This is generally acceptable for flashcard "favorites" which are usually intended to be complete contexts. If the user wants a single word, they usually select just the word and the `term` logic handles it, but this specific change is for the `source_sentence` (context) field.
