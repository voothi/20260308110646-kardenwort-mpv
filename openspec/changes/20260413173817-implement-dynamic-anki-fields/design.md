## Context

The current Anki export implementation in `lls_core.lua` is rigid, supporting only three hardcoded columns (`term`, `context`, `time`). This design introduces a dynamic field-mapping layer that allows the user to define their own set of columns in `mpv.conf` and link them to internal data sources.

## Goals / Non-Goals

**Goals:**
- Decouple the TSV column structure from the export logic.
- Implement a position-based field list in `mpv.conf` supporting "holes" for empty columns.
- Automate deck and language detection based on subtitle filenames.
- Inject Anki's specific `#deck column:N` header for automated imports.

**Non-Goals:**
- Building a full Anki-Connect integration (stays TSV-based).
- Implementing a full lemmatizer inside Lua (uses raw selections as `source_word`).

## Decisions

### Decision 1: Comma-Separated Field List with `\` Support
**Rationale**: `mpv.conf` is line-based but supports backslash continuation. By defining `anki_fields` as a comma-separated list wrapped across multiple lines, users can maintain a clean, vertical list where order is implicitly preserved without needing rigid index numbers (e.g., `field_01`).
**Alternatives**: Using a separate `.ini` file (too complex for user) or rigid indexing `anki_field_NN` (too hard to maintain when inserting fields).

### Decision 2: Field Resolution via Mapping Table
**Rationale**: We separate the *name* of the field from its *source*. A field `Quotation` can be mapped to `source_word` in "Word Mode" but `source_sentence` in "Sentence Mode".
**Logic**:
- Split `anki_fields` by `,`.
- For each field, check `anki_mapping_word` or `anki_mapping_sentence` for the source key.
- If no mapping/dash, output empty string.

### Decision 3: Metadata Extraction from Primary Track
**Rationale**: The primary subtitle filename contains both the deck name (base) and the language (postfix). We will capture `Tracks.pri.path` and use regex to extract `deck_name` and `lang_code`.
- Deck: `file.de.srt` -> `file.de`
- TTS Flag: `de` -> sets `tts_source_de=1`

### Decision 4: Dynamic Header Generation
**Rationale**: To support `#deck column:N`, the writer must determine the index of the column containing the `deck_name` source before writing the file.
**Logic**: Find the 1-based index of the first field mapped to `deck_name`.

## Risks / Trade-offs

- **[Risk]** Filenames with non-standard patterns (e.g. `video.srt` without lang code).
- **[Mitigation]** Fallback `lang_code` to "und" and `deck_name` to full filename (minus ext).
- **[Trade-off]** `mpv.conf` parsing of long wrapped strings requires care with trailing whitespaces. We will use string trimming in Lua.
