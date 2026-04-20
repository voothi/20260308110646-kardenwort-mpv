## Context

The `dw_anki_export_selection` function successfully generates an `advanced_index` (a comma-separated Multi-Pivot map of `LineOffset:WordIndex:TermPos`). While this index is correctly saved to the TSV, the subsequent call to `extract_anki_context` still relies on `pivot_pos`— a geometric midpoint calculated by string length. This creates a disconnect where the system "knows" exactly which word it mined but "guesses" which word to extract context for if multiple instances of the term exist in the viewport.

## Goals / Non-Goals

**Goals:**
- Transition the context search engine to use logical coordinate grounding (`advanced_index`) as the primary anchor.
- Eliminate "occurrence ambiguity" in subtitle segments with repeated terms.
- Maintain support for legacy records (geometric fallback).

**Non-Goals:**
- Implementing "Fractional Indexing" for punctuation (reserved for future hardening).
- Changing the TSV schema or `anki_mapping.ini` structure.

## Decisions

### 1. Unified Interface for `extract_anki_context`
We will replace the `pivot_pos` argument with `coord_map`.
- **Rationale**: The `advanced_index` contains all necessary metadata to resolve the exact word occurrence without needing geometric hints.
- **Alternatives**: Passing both parameters was considered, but `coord_map` renders `pivot_pos` obsolete for all modern records.

### 2. Multi-Pivot Resolution Logic
The extractor will iterate through candidates using `string.find` and verify them by checking if their logical word index matches the `WordIndex` of the first pivot in the map.
- **Implementation**: We must temporarily parse the current subtitle line into tokens within the extractor (or pass pre-parsed tokens) to perform the logical-to-byte comparison.

### 3. Selective Fallback
If the `coord_map` is missing or invalid (legacy records), the engine will revert to the existing geometric midpoint logic.

## Risks / Trade-offs

- **[Performance Overhead]** → Parsing tokens again during extraction might add a few milliseconds. *Mitigation*: Only perform full tokenization if a `coord_map` is present and multiple string matches are found.
- **[Drift Incompatibility]** → If the subtitle database has changed since the record was saved, the logical map might fail. *Mitigation*: Implement a `+/- 1` segment drift tolerance as specified in the indexing requirement.
