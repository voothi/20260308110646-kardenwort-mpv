## 1. Configuration & Metadata

- [ ] 1.1 Update `Options` table to include sequenced fields (`anki_field_1` through `anki_field_20`), `anki_mapping_word`, `anki_mapping_sentence`, and `anki_deck_name`
- [ ] [turbo] 1.2 Implement a loop utility to aggregate the sequentially numbered `anki_field_*` options into an ordered field array, preserving empty string values as holes
- [ ] 1.3 Add a filename parsing utility to extract the `deck_name` (base + lang postfix) and `lang_code` from `Tracks.pri.path`

## 2. Dynamic Export Engine

- [ ] 2.1 Implement the data source resolver that maps internal variables (`term`, `context`, `time`, `deck_name`, `tts_source_[lang]`) to field names
- [ ] 2.2 Implement the `tts_source_[lang]` flag logic based on the extracted `lang_code`
- [ ] 2.3 Add a TSV escaping utility to safely handle literal tabs and newlines within exported fields

## 3. TSV File I/O & Header Generation

- [ ] 3.1 Refactor `save_anki_tsv_row` to use the dynamic field list instead of hardcoded columns
- [ ] 3.2 Implement logic to find the 1-based index of the `deck_name` column for the Anki header
- [ ] 3.3 Implement the automatic `#deck column:N` header injection for new/empty TSV files

## 4. Mode Integration & Testing

- [ ] [turbo] 4.1 Update `dw_anki_export_selection` to correctly pass the current mode (word vs sentence) to the resolver
- [ ] 4.2 Verify that "holes" (leaving an `anki_field_*` option blank) result in correct empty columns in the TSV
- [ ] 4.3 Verify that `#deck column:N` matches the actual position of the deck name in the exported file
