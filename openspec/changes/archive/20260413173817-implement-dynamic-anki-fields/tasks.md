## 1. Configuration & Metadata

- [x] 1.1 Create a lightweight `ini` parser utility in `lls_core.lua` to read configuration from `~~/anki_mapping.ini`
- [x] [turbo] 1.2 Parse the `[fields]` section strictly line-by-line into an ordered array (preserving blank lines as holes), and load the `[mapping]` and `[tts]` key-value pairs
- [x] 1.3 Add a filename parsing utility to extract the `deck_name` (base + lang postfix) and `lang_code` from `Tracks.pri.path`
- [x] 1.4 Expand metadata extraction to capture the secondary subtitle language code for destination flags

## 2. Dynamic Export Engine

- [x] 2.1 Implement the data source resolver that maps internal variables (`term`, `context`, `time`, `deck_name`, `tts_source_[lang]`, `tts_dest_[lang]`) to field names
- [x] 2.2 Implement the `tts_source_[lang]` (primary) and `tts_dest_[lang]` (secondary) flag logic
- [x] 2.3 Implement the automatic Russian destination fallback logic (`tts_dest_ru=1` if no secondary track persists)
- [x] 2.4 Add a TSV escaping utility to safely handle literal tabs and newlines within exported fields

## 3. TSV File I/O & Header Generation

- [x] 3.1 Refactor `save_anki_tsv_row` to use the dynamic field list instead of hardcoded columns
- [x] 3.2 Implement logic to find the 1-based index of the `deck_name` column for the Anki header
- [x] 3.3 Implement the automatic `#deck column:N` header injection for new/empty TSV files

## 4. Mode Integration & Testing

- [x] [turbo] 4.1 Update `dw_anki_export_selection` to correctly pass the current mode (word vs sentence) to the resolver
- [x] 4.2 Verify that "holes" (blank values in the INI file) result in correct empty columns in the TSV
- [x] 4.3 Verify that `#deck column:N` matches the actual position of the deck name in the exported file
