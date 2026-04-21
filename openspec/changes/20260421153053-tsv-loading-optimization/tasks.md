## 1. Core State & Utility Extension

- [x] 1.1 Add `ANKI_DB_MTIME` and `ANKI_DB_SIZE` fields to the `FSM` table initialization.
- [x] 1.2 Initialize fingerprint fields to `0` and ensure they are reset whenever the `ANKI_DB_PATH` change is detected.

## 2. Optimized TSV Loading

- [x] 2.1 Refactor `load_anki_tsv` to calculate fingerprint before parsing.
- [x] 2.2 Implement conditional return if fingerprint matches, `ANKI_HIGHLIGHTS` is populated, and `force` is false.
- [x] 2.3 Move fingerprint update logic to the end of the `load_anki_tsv` function (after successful parse completion).
- [x] 2.4 Fix regression: Ensure `utils.file_info` is used instead of incorrectly namespaced `mp.utils.file_info`.
- [x] 2.5 Add descriptive console logging for skip and load events.

## 3. URL Discovery Optimization

- [x] 3.1 Introduce `SOURCE_URL_FILE_MTIME` and `SOURCE_URL_FILE_SIZE` to the global state.
- [x] 3.2 Refactor `find_source_url` to check fingerprint of the already discovered `SOURCE_URL_FILE_PATH`.
- [x] 3.3 Ensure the directory scan is skipped if the current cached URL file is still valid and unchanged.

## 4. Verification & Hardening

- [x] 4.1 Verify that the "Advanced Index" build loop is avoided during periodic syncs when the TSV remains unchanged.
- [x] 4.2 Verify that adding a new highlight correctly invalidates the fingerprint and triggers a fresh reload.
- [x] 4.3 Verify that selecting external subtitles correctly resets the database path and fingerprint.
