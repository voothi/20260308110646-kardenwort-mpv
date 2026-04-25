## Context

The Drum Window implementation allows for "decoupled" navigation in Book Mode, where a stationary yellow pointer (manual focus) and a moving white highlight (playback/navigation focus) coexist. A regression was identified where `Ctrl+C` (copy) only respected the stationary yellow pointer, making it impossible to copy lines reached via `a`/`d` seeks without manually moving the yellow pointer. Additionally, specification compliance issues were found in context-copy word splicing and formatting preservation.

## Goals / Non-Goals

**Goals:**
- Implement a focus-priority system for the copy command that adapts to Book Mode navigation.
- Ensure "Verbatim Selection with Context" compliance by correctly splicing selections into surrounding context.
- Preserve all text formatting (brackets, punctuation) to satisfy "Copy as is" requirements.
- Maintain independent pointer behavior for visual focus while allowing copy focus to follow navigation.

**Non-Goals:**
- Changing the visual behavior of the independent pointer.
- Redesigning the `get_copy_context_text` underlying logic.

## Decisions

- **Focus Priority Fallback**: In Book Mode, if `FSM.DW_FOLLOW_PLAYER` is active (meaning the view is following navigation or playback) and no explicit word/range selection is present, `cmd_dw_copy` will use `FSM.DW_ACTIVE_LINE`.
- **Pre-cleaning for Context Splicing**: To ensure `gsub` successfully matches the focal line within a context block (which might contain ASS tags), the context string is now cleaned of `{...}` tags before the replacement occurs.
- **Punctuation Preservation**: The "Clean capture" logic that previously stripped leading/trailing punctuation (using `%p`) is removed to ensure brackets like `[räuspern]` are preserved in the clipboard.
- **ASS Tag Removal**: Formatting tags are still removed from the final clipboard string to keep it clean for external use (dictionaries, etc.), but this is done only once at the end.

## Risks / Trade-offs

- **[Risk] Pattern Match Collision** → If multiple context lines are identical to the focal line, `gsub` will replace all of them. This is generally acceptable in subtitle contexts as it maintains consistency across the copied block.
- **[Trade-off] Loss of Word Cleaning** → Removing the punctuation stripping means word-level copies (e.g., clicking a single word) will now include attached punctuation (e.g., "word," instead of "word"). This is a direct trade-off to satisfy the "Copy as is" requirement for full lines.
