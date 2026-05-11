## Why

The current export logic in `lls_core.lua` deviates from the "Verbatim" requirement established in recent OpenSpec changes. Specifically, the system still collapses multiple spaces into one and strips semantic brackets (like `[]`) in the context field during Anki export. Furthermore, the field mapping logic relies on a non-deterministic Lua table structure, making it impossible for users to control the TSV column sequence via the order of assignments in `anki_mapping.ini`.

## What Changes

- **Remove Whitespace Normalization**: Eliminate all `gsub("%s+", " ")` calls from the Anki context extraction path in `dw_anki_export_selection` and related helpers.
- **Strict Metadata Stripping**: Restrict automatic symbol stripping in export paths to ASS tags (`{...}`) only. Semantic brackets (e.g., `[Musik]`) must be preserved verbatim.
- **Ordered Field Mapping**: Refactor `load_anki_mapping_ini` to preserve the assignment order within `[fields_mapping.*]` sections, allowing the INI file's line order to determine the TSV column sequence.
- **Unified Export Preparation**: Ensure `prepare_export_text` is the exclusive service used for text preparation, consolidating cleaning logic to prevent future regressions.

## Capabilities

### New Capabilities
- None

### Modified Capabilities
- `anki-export-mapping`: Update requirements to enforce ordered column mapping and absolute verbatim context fidelity.
- `export-engine-hardening`: Refine content validation to respect verbatim whitespace and preserve semantic markers.

## Impact

- `scripts/lls_core.lua`: Core refactor of `load_anki_mapping_ini`, `dw_anki_export_selection`, and `prepare_export_text`.
- `anki_mapping.ini`: Assignment order now determines TSV column sequence.
