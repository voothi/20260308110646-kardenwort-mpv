## Context

The recent transition to a "Surgical" highlighting model and "Verbatim" export requirement has left several legacy "smart" cleaning routines in `lls_core.lua`. Specifically, the system still collapses spaces and strips square brackets in the Anki context field. Additionally, the Anki field mapping logic currently uses unordered Lua tables, which prevents users from defining the TSV column sequence directly via assignment order in the INI file.

## Goals / Non-Goals

**Goals:**
- Achieve 100% verbatim fidelity for the `SentenceSource` (context) field in Anki exports.
- Implement deterministic, order-preserving field mapping for the Anki TSV export.
- Consolidate all export text preparation into a single, high-fidelity pathway.

**Non-Goals:**
- Modifying the visual rendering of OSD subtitles (which requires typographic spacing for legibility).
- Changing the underlying `utf8_to_table` or `build_word_list_internal` logic.

## Decisions

### 1. Order-Preserving INI Parsing
The `load_anki_mapping_ini` function will be refactored to preserve the order of field assignments.
- **Implementation**: Instead of directly assigning to a map (`config.mapping_word[k] = v`), the parser will populate a `fields` array in the order keys are encountered if no explicit `[fields]` section is provided.
- **Rationale**: Complies with Requirement 19, allowing the INI file structure to act as the source of truth for TSV column ordering.

### 2. Removal of Whitespace and Bracket Normalization
All `gsub("%s+", " ")` and `gsub("%b[]", " ")` calls will be removed from the export and context extraction paths in `dw_anki_export_selection` and `prepare_export_text`.
- **Rationale**: Direct adherence to Requirements 112 and 125. Context must reflect the source subtitle file exactly, including multiple spaces and semantic markers like `[Musik]`.

### 3. High-Fidelity `clean_anki_term` Refactor
The `clean_anki_term` helper will be simplified to strictly remove ASS tags `{...}` and perform a simple trim of the entire string.
- **Decision**: No character-level stripping or balanced bracket removal will be performed here.

### 4. Hardened Empty-Content Validation
The "Minimum Content" check will be updated to ensure it doesn't accidentally discard verbatim text that might consist of non-alphanumeric symbols (like `[...]`), while still correctly ignoring purely whitespace or tag-only selections.

## Risks / Trade-offs

- **Risk**: Card layouts that previously relied on "clean" context (no `[]`) will now see those brackets. However, this is consistent with the project's move toward data fidelity.
- **Trade-off**: The INI parser becomes slightly more complex to maintain order, but the UX improvement for card design is significant.
