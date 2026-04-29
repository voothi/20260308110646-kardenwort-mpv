# Design: Unified Export String Engine

## Context
Currently, string preparation for export (Clipboard and Anki TSV) is fragmented across multiple functions: `cmd_dw_copy`, `cmd_copy_sub`, `dw_anki_export_selection`, and `ctrl_commit_set`. Each implements its own logic for joining tokens, cleaning text, and handling selection boundaries. This leads to discrepancies, such as `Ctrl+C` preserving symbols while Anki export strips them, and "smart" joiners incorrectly altering original subtitle spacing.

## Goals / Non-Goals

**Goals:**
- Centralize all export string preparation into a single robust function: `prepare_export_text`.
- Achieve "verbatim fidelity" by default, preserving original spacing and punctuation tokens.
- Support symbol-level selection granulation for both mouse and keyboard interactions.
- Ensure consistency between all export paths (Clipboard and TSV).

**Non-Goals:**
- Changing the underlying tokenizer or index (index remains word-based).
- Altering OSD rendering logic (OSD will still use `compose_term_smart` for typography).

## Decisions

### Decision 1: The `prepare_export_text` Unified Service
A new central function will be implemented to handle all export string construction. It will accept a selection object (Range, Set, or Point) and return a cleaned, joined string.

### Decision 2: Fractional Index Bounds Checking
To support symbol-level precision, the engine will use strict `>=` and `<=` comparisons against `logical_idx` values (which are fractional for punctuation/spaces). This allows mouse selections that "land" on symbols to include them in the export without special-casing punctuation tokens.

### Decision 3: Verbatim Token Joining
By default, the engine will use `build_word_list_internal(text, true)` to retrieve all tokens (including original whitespace). These tokens will be concatenated directly (`table.concat`) rather than being passed through the "smart" joiner, which often misinterprets original intent in its attempt to apply typographic rules.

### Decision 4: Surgical Cleaning in `clean_anki_term`
The `clean_anki_term` function will be refactored to remove aggressive punctuation stripping. It will retain:
- ASS tag removal (`{...}`).
- Space normalization (collapsing multiple spaces).
- External bracket stripping (only if they wrap the entire selection as a "wrapper").
- It will STOP stripping leading/trailing symbols that were explicitly part of the selection range.

## Risks / Trade-offs

### Risk: Selection "Bleed"
Including original spacing tokens might lead to unwanted leading/trailing spaces if the selection bounds are not precisely calculated.
- **Mitigation**: The engine will include a final `.match("^%s*(.-)%s*$")` pass to ensure the resulting block is trimmed of external whitespace while preserving internal formatting.

### Trade-off: Loss of OSD Typography in Exports
Users might occasionally prefer the "smart" spacing for exports.
- **Mitigation**: The `verbatim` mode will be the default for maximum fidelity, but the engine will support an optional `use_smart_joiner` flag if specific cards require it (though none are currently planned).
