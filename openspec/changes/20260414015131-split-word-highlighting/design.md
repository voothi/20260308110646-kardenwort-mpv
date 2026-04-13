## Context

Currently, the Drum Window allows the user to select and export non-contiguous words via `Ctrl+LMB` followed by `Ctrl+MMB`. These selected words are ordered and joined by a single space into a compound term within the TSV export. 

However, the visual highlighting system currently attempts to match terms exactly against the contiguous subtitle text block. Since non-contiguous words are interrupted by other words in the actual text, the exact continuous string match fails, and the exported paired words lose all highlights, returning to their default unselected color. The user intends for these "split words" to be persistently highlighted in a distinct color (purple) to differentiate them from standard contiguous selections (orange) and confirm their status in the exported datastore.

## Goals / Non-Goals

**Goals:**
- Identify terms from the TSV database that represent multi-word clusters but cannot be matched as literal contiguous strings in the text.
- Match the individual constituent words of these non-contiguous TSV terms when they appear together in the text context.
- Render these successfully matched non-contiguous components using a newly introduced "split term" color (like purple).

**Non-Goals:**
- Providing perfect linguistic grammar matching. We will rely on simple string set intersection within the bounded context (line or block) to apply highlights.
- Altering the Anki format. The terms will continue to be exported as space-joined strings, preserving the existing data structure.

## Decisions

1. **Split-Term Registration in highlight_dict**:
   During the parsing of the TSV file into the `highlight_dict`, terms containing a space character will be parsed as multi-word arrays in addition to literal strings. This enables the text engine to track both literal contiguous phrases and sets of split words.

2. **Presence Verification Logic**:
   While constructing the rendering tags (e.g., inside `build_word_tags` in `lls_core.lua`), the system will check the current subtitle block constraints against registered split terms. If **all** constituent words of a specific split term are present in the same block, the corresponding rendered screen words will apply the split-term color.

3. **Color Configurations**:
   Introduced a new configuration key `split_highlight_color` (defaulting to a purple hex code, e.g., `#B088FF`) to match user expectations. 

4. **Rendering Precedence**:
   - Exact contiguous string matches maintain priority, receiving standard highlight colors.
   - Matched split-term words receive the new split-term purple highlight.

## Risks / Trade-offs

- **[Risk: False Positives in Split Matching]** → Mitigation: Enforce that all individual split-words constituting the TSV term must occur within the same short contextual block (like the current subtitle sequence) for the highlight to engage. If 'mache' is present but 'auf' is not, it will not highlight.
- **[Risk: Render Loop Overhead]** → Mitigation: Checking word intersection lists can increase rendering complexity. We will cache split-term array permutations per TSV reload and limit the scope of searches to the currently visible subtitle block to maintain fast operation limits.
