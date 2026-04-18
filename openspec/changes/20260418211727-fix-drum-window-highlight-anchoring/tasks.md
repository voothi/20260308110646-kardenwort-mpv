## 1. Configuration and Field Mapping

- [ ] 1.1 Map `SentenceSourceIndex` to `source_index` in `anki_mapping.ini` to allow logical index storage.
- [ ] 1.2 Update the `load_anki_mapping_ini` parser to recognize and skip lines starting with a semicolon (`;`).

## 2. Exporter Hardening (Anchoring)

- [ ] 2.1 Refactor `dw_anki_export_selection` to calculate a character-offset `pivot_pos` for the user's specific selection.
- [ ] 2.2 Re-scope the `pivot_pos` variable to ensure it is accessible to the final context extraction call (fix shadowing).
- [ ] 2.3 Update `extract_anki_context` to iterate through all term candidates and select the one with the smallest distance to the pivot.

## 3. Highlighting Engine (Grounding)

- [ ] 3.1 Modify `calculate_highlight_stack` to strictly enforce `data.index` matching for orange highlights.
- [ ] 3.2 Implement a legacy fallback that uses the improved pivot-point context matching even if an index is missing.

## 4. Telemetry and Diagnostics

- [ ] 4.1 Add temporary console logging for `Word List` and `Candidate Search` to allow real-time precision verification.
- [ ] 4.2 Clean up diagnostic logic once anchoring stability is confirmed.
