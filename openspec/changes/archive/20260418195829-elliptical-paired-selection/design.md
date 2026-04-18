## Context

The Kardenwort-mpv highlighting engine uses a three-phase approach: Contiguous (Orange), Contextual (Depth/Orange), and Split (Purple). Currently, if a user selects non-adjacent words (e.g., "Sie" ... "Hören"), the system saves them as a joined phrase "Sie Hören." Because the database contains this phrase, the highlighter marks ALL occurrences of "Sie hören"—including contiguous ones—in orange. The user has requested a way to differentiate these "paired selections" to avoid distracting highlights on unrelated contiguous phrases.

## Goals / Non-Goals

**Goals:**
- Detect non-contiguity during the Drum Window selection/export process.
- Inject a `...` (ellipsis) marker into split terms saved to the TSV.
- Update the highlighter to treat terms with ellipses as "Split-Only" targets.
- Maintain backward compatibility for existing database records.

**Non-Goals:**
- Removing the ability to highlight contiguous phrases in orange (this remains the default behavior for standard phrases).
- Changing the TSV schema or metadata format beyond the string content of the term field.

## Decisions

### 1. Gap Detection in Exporter
- **Decision**: Modify the multi-word range extraction logic in `lls_core.lua` to compare the `logical_idx` of each word in a selection.
- **Rationale**: The `logical_idx` established during subtitle tokenization ensures that we can distinguish between adjacent words and words separated by punctuation or spaces. If `logical_idx[n+1] != logical_idx[n] + 1`, a gap exists.

### 2. Lexical Marker (` ... `)
- **Decision**: Join split words with a literal space-padded ellipsis: ` ... ` (space, three dots, space).
- **Rationale**: This is a standard linguistic convention for truncated text and provides "plural spaces" for clear visual separation. It is easily detectable via `string.find(term, " ... ", 1, true)` in Lua.

### 3. Highlighter Logic Gating
- **Decision**: Introduce a conditional bypass in `calculate_highlight_stack`. If `term:find("...", 1, true)`, Phase 1 & 2 (Contiguous/Contextual) logic is skipped.
- **Rationale**: This prevents "Orange Bleed." A term like `Sie ... Hören` will never match `Sie hören` contiguously, fulfilling the user's requirement to keep these distinct. Phase 3 (Split matching) remains active and will correctly highlight the split components in purple.

## Risks / Trade-offs

- **[Risk] High-Recall Loss** → By making some matches "Split-Only," we reduce the total number of highlights. However, this is specifically what the user requested to reduce "distraction." Standard phrase matches (no ellipses) remain high-recall.
- **[Risk] String Normalization** → Existing code that strips punctuation for matching must be careful not to strip the ellipsis *before* the gating check occurs.
- **[Trade-off] Manual Control** → This change shifts control to the selection phase. If a user *wants* a split selection to also highlight contiguous instances, they would need to manually remove the dots in their TSV (or we provide a toggle later).
