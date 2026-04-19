## 1. Core Logic: URL Discovery

- [x] 1.1 Implement `find_source_url()` in `lls_core.lua` to scan for `.url`, `.txt`, and `.md` files using `utils.readdir` and `utils.split_path`.
- [x] 1.2 Implement internal `parse_url_file` helper with case-insensitive `URL=` pattern matching and BOM handling.
- [x] 1.3 Add persistent caching for `SOURCE_URL_CACHE` and `SOURCE_URL_FILE_PATH` to minimize disk I/O.
- [x] 1.4 Implement cache validation logic to detect file renames or deletions before returning cached values, triggering a re-scan.

## 2. Integration: Anki Export Engine

- [x] 2.1 Update `resolve_anki_field` to support the `source_url` data source keyword.
- [x] 2.2 Wire `find_source_url()` into the `anki_sync_period` periodic timer loop to support files added after playback starts.

## 3. Configuration & Defaults

- [x] 3.1 Map `SourceURL` to `source_url` in `anki_mapping.ini` for both `.word` and `.sentence` profiles.
- [ ] 3.2 (Cleanup) Remove any lingering stub mappings in `anki_mapping.ini` that might have been introduced during previous iterations.
