## Why

Resolve a persistent "highlight bleed" regression in the Drum Window where common words (e.g., "die") in one subtitle segment caused incorrect highlight associations with identical words in nearby segments. This change hardens the connection between a manual selection and its stored record.

## What Changes

- **Word Index Anchoring**: Implemented strict index-based matching for Anki records by mapping `source_index` to the exported TSV.
- **Pivot-Point Context Extraction**: Refactored the context search engine to anchor itself to the specific character offset of the user's click, preventing "drifting" to earlier/later occurrences of common terms.
- **INI Comment Support**: Updated the configuration parser to correctly skip lines starting with a semicolon (`;`), preventing TSV header corruption.
- **Telemetry and Diagnostics**: Added switchable export diagnostics to the console to verify word-list tokenization and search pivots in real-time.

## Capabilities

### New Capabilities
- `drum-window-indexing`: Implements logical word-level indexing and pivot-point anchoring to enable 100% precision in subtitle selection and record association.

### Modified Capabilities
- `subtitle-highlighting`: updated grounding logic to strictly enforce index matching, preventing automated highlights from "bleeding" into identical words in different contexts.

## Impact

- **scripts/lls_core.lua**: Core logic for context extraction, INI parsing, and highlight calculation.
- **script-opts/anki_mapping.ini**: Field mappings for Anki exports.
- **Anki TSV Records**: Data now includes a `SentenceSourceIndex` for absolute grounding.
