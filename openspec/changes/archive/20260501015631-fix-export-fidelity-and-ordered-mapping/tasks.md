## 1. Ordered Mapping Implementation

- [x] 1.1 Refactor `load_anki_mapping_ini` to track key assignment order for `fields_mapping.*` sections.
- [x] 1.2 Update the mapping logic to automatically populate `config.fields` from the ordered assignment list if the `[fields]` section is missing.

## 2. Export Fidelity Restoration

- [x] 2.1 Remove all whitespace normalization (`gsub("%s+", " ")`) from context extraction loops in `dw_anki_export_selection`.
- [x] 2.2 Remove semantic bracket stripping (`gsub("%b[]", " ")`) from all export paths.
- [x] 2.3 Refactor `clean_anki_term` to strictly perform ASS tag removal and trimming only.
- [x] 2.4 Consolidate `SentenceSource` construction in `dw_anki_export_selection` to use verbatim token concatenation.

## 3. Engine Hardening

- [x] 3.1 Update the "Minimum Content" validation check to be verbatim-aware (allowing brackets and symbols as valid characters).
- [x] 3.2 Ensure `prepare_export_text` correctly handles verbatim markers across all export types (RANGE, POINT, SET).

## 4. Verification & Testing

- [x] 4.1 Verify TSV column order matches `anki_mapping.ini` assignment order.
- [x] 4.2 Validate that `SentenceSource` in Anki contains verbatim spaces and `[]` brackets.
- [x] 4.3 Confirm that ASS tags are still correctly removed from all export fields.
