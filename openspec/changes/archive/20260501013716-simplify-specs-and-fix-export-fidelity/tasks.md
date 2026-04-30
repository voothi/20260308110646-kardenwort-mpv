## 1. Export Fidelity Fixes

- [x] 1.1 Remove `gsub("%s+", " ")` normalization from `clean_anki_term` in `lls_core.lua`.
- [x] 1.2 Remove `gsub("%s+", " ")` normalization from the `options.clean` fallback in `prepare_export_text`.
- [x] 1.3 Verify that multiple spaces are preserved in both Clipboard and TSV exports.

## 2. Specification Cleanup

- [x] 2.1 Update `openspec/specs/anki-highlighting/spec.md` to remove Requirements 103 and 114.
- [x] 2.2 Update `openspec/specs/unified-drum-rendering/spec.md` to align Requirement 13 with the Surgical Model.
- [x] 2.3 Update `openspec/specs/anki-export-mapping/spec.md` to clarify the Absolute Verbatim mandate for whitespace.

## 3. Regression Verification

- [x] 3.1 Confirm that highlighting remains strictly bound to word tokens in both Drum Mode and Drum Window.
- [x] 3.2 Ensure metadata brackets `[...]` and `(...)` are NOT colored during database matches.
- [x] 3.3 Verify that manually selected brackets ARE included in the export (Verbatim fidelity).
