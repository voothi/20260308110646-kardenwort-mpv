## Context

The `anki_strip_metadata` feature was introduced to keep Anki cards clean by removing subtitle technical tags like `[musik]`. However, the implementation uses a simple `gsub("%b[]", " ")` which wipes out any bracketed content, even if it's the intended vocabulary word (e.g., `[UMGEBUNG]`). 

Furthermore, the high-recall highlighter uses strict context matching, where a word must have at least one neighbor matching the saved context. Since metadata tags are stripped from the saved context but remained in the player's subtitle text, words adjacent to these tags lose their highlights because their "neighbor" (the tag) is missing from the context.

## Goals / Non-Goals

**Goals:**
- Allow users to export terms that are enclosed in brackets by stripping only the brackets and preserving the content if it's the primary selection.
- Fix highlighting for words adjacent to metadata tags by making the highlighter "skip" or tolerate missing metadata neighbors.
- Maintain the "clean context" principle for Anki cards.

**Non-Goals:**
- Removing the `anki_strip_metadata` feature entirely.
- Implementing a complex NLP-based metadata classifier.

## Decisions

- **Selective Stripping**: In `dw_anki_export_selection`, before applying `gsub("%b[]", " ")`, check if the resulting string is empty or just whitespace. If so, revert to the original term but strip only the `[` and `]` characters.
- **Metadata-Tolerant Highlighting**: In `calculate_highlight_stack`, update the neighbor check logic. If a neighbor matches the `%b[]` pattern AND `anki_strip_metadata` is enabled, treat that neighbor as "valid" (or skip it) so it doesn't trigger a strict context mismatch for the word being checked.
- **Multi-word (Purple) Selection Support**: In `ctrl_commit_set`, ensure that it also respects `anki_strip_metadata` by stripping brackets from individual words when they are collected into the final term. This ensures that a multi-word selection containing metadata tags (often represented by split/purple highlights after saving) correctly filters those tags.
- **Consistency**: Apply similar "selective stripping" to `ctrl_commit_set` so that manual multi-word selections also benefit from this fix.

## Risks / Trade-offs

- **Risk**: Some intentional metadata like `[musik]` might be saved as `musik` if the user clicks exactly on it. This is a acceptable trade-off as it's better than saving an empty string, and the user can always delete the card.
- **Complexity**: The highlighter logic becomes slightly more complex but remains performant as it only checks nearby neighbors.
