## 1. Core Parser Hardening

- [ ] 1.1 Update `clean_text_srt` in `lls_core.lua` to trim leading and trailing whitespace using `gsub("^%s*(.-)%s*$", "%1")`.
- [ ] 1.2 Verify that `load_sub` correctly identifies empty separator lines in SRT files even when they contain whitespace.

## 2. TSV Sync Engine Compliance

- [ ] 2.1 Wrap the file-reading loop in `load_anki_tsv` (around line 2502) with a `pcall` guard to satisfy `tsv-state-recovery:REQ-9`.
- [ ] 2.2 Purge hardcoded header string checks (`"WordSource"`, `"Term"`) from the `is_header` logic in `load_anki_tsv`.
- [ ] 2.3 Ensure the `term_header_name` derived from `anki_mapping.ini` is the primary mechanism for header row exclusion.

## 3. Branding & Metadata Synchronization

- [ ] 3.1 Update the project title in the `lls_core.lua` file header (line 2) to canonical "Language Acquisition Suite".
- [ ] 3.2 Perform a global search in `lls_core.lua` for legacy "Learning Suite" references and synchronize them with the historicity ledger.
