## Why

The current Anki export logic is hardcoded to a fixed set of columns, which limits compatibility with sophisticated Anki Note Types that require specific field mappings (e.g., separating inflected forms, adding TTS flags, or auto-organizing into sub-decks). This change introduces a dynamic, position-based mapping system that mirrors the flexibility of the main Kardenwort project, allowing users to configure their export format in a clean, dedicated `anki_mapping.ini` file with automatic deck organization based on video/subtitle filenames.

## What Changes

- **External INI Config**: Moving Anki field definitions out of the strict `mpv.conf` parser and into a dedicated `anki_mapping.ini` file to allow clean, vertical configuration.
- **Flexible Mappings**: Introduction of `anki_mapping_word` and `anki_mapping_sentence` to link Anki fields to internal data sources (`source_word`, `source_sentence`, `time`, `deck_name`).
- **Hole Support**: Ability to define "holes" in the INI field list (leaving a key blank) to produce empty Anki columns.
- **Smart Metadata Extraction**: Automatic extraction of deck names and language codes from the primary subtitle filename (e.g., `file.de.srt` -> deck `file.de`, language `de`).
- **Automated Anki Headers**: Generation of the `#deck column:N` header at the start of the TSV for zero-touch Anki imports.
- **Dynamic TTS Flags**: Support for `tts_source_[lang]` sources that automatically set a field to "1" based on the subtitle language postfix.

## Capabilities

### New Capabilities
- `anki-export-mapping`: Dynamic configuration of TSV columns, automatic deck organization, and language-aware TTS flag activation via an external string mappings file.

### Modified Capabilities
- `mmb-drag-export`: Update the export trigger to use the new dynamic mapping engine instead of hardcoded columns.

## Impact

- `scripts/lls_core.lua`: Significant refactor of the export and TSV writing logic, plus addition of a small INI parser.
- `anki_mapping.ini`: New configuration file schema for defining Anki fields and settings.
