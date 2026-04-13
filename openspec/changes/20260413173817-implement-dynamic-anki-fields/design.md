## Context

The current Anki export implementation in `lls_core.lua` is rigid, supporting only three hardcoded columns (`term`, `context`, `time`). This design introduces a dynamic field-mapping layer that allows the user to define their own set of columns in a dedicated `anki_mapping.ini` file and link them to internal data sources.

## Goals / Non-Goals

**Goals:**
- Decouple the TSV column structure from the export logic.
- Implement a line-by-line field list in `anki_mapping.ini` supporting "holes" for empty columns.
- Automate deck and language detection based on subtitle filenames.
- Inject Anki's specific `#deck column:N` header for automated imports.

**Non-Goals:**
- Building a full Anki-Connect integration (stays TSV-based).
- Implementing a full lemmatizer inside Lua (uses raw selections as `source_word`).

## Decisions

### Decision 1: Dedicated INI Configuration
**Rationale**: `mpv.conf` is strictly parsed and does not handle multiline strings or complex escaped characters well, leading to window-scaling bugs. Moving to `script-opts/anki_mapping.ini` allows for a clean, vertical configuration without interfering with MPV's core parser.

### Decision 2: Positional Field List
**Rationale**: In the `[fields]` section of the INI, each line represents a column. This provides high legibility and allows for "holes" (empty columns) simply by leaving a blank line.

### Decision 3: Unified Field Resolution
**Rationale**: We separate the *name* of the field from its *source*. A field is mapped once in the `[mapping]` or `[tts]` section. During export, the system resolves the value based on the current context (e.g. `source_word` returns the selected text, while `source_sentence` returns the extracted line).

### Decision 4: Dual-Track Metadata Extraction
**Rationale**: The system distinguishes between the **Source** (Primary track) and the **Destination** (Secondary track). We capture metadata from both tracks to enable language-specific TTS flagging.
- **Source Logic**: `tts_source_[lang]` checks the language postfix of the currently active primary subtitle.
- **Destination Logic**: `tts_dest_[lang]` checks the language postfix of the currently active secondary subtitle.
- **Smart Fallback**: If no secondary subtitle is loaded, any field mapped to `tts_dest_ru` automatically resolves to `1` as the default study destination. Explicit overrides (`="1"` in INI) take final precedence.

### Decision 5: Dynamic Header Generation
**Rationale**: To support `#deck column:N`, the writer determines the index of the column containing the `deck_name` source by scanning the `[fields]` list and verifying the mapping.

## Risks / Trade-offs

- **[Risk]** Filenames with non-standard patterns (e.g. `video.srt` without lang code).
- **[Mitigation]** Fallback `lang_code` to empty string and `deck_name` to base filename.
- **[Trade-off]** Reading an extra file on every export/sync.
- **[Optimization]** The INI configuration is cached in memory and only re-read when the script initializes or explicit reloads occur.
