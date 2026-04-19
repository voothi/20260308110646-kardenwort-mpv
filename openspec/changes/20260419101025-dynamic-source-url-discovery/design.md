## Context

Currently, the `save_anki_tsv_row` function in `lls_core.lua` maps Anki fields using a static configuration from `anki_mapping.ini`. While it supports hardcoded data sources like `source_word` and `source_sentence`, it lacks a mechanism to dynamically source metadata from external filesystem breadcrumbs, such as YouTube `.url` shortcuts or `.txt` / `.md` sidecar files.

## Goals / Non-Goals

**Goals:**
- Implement a lightweight, lazy-loaded discovery scanner for meta-data source files.
- Support standard Windows Internet Shortcut (`.url`) and common text (`.txt`, `.md`) formats.
- Integrate discovery into the existing `resolve_anki_field` pipeline via a new `source_url` keyword.
- Ensure automated discovery is resilient to filesystem changes (renames/deletions) during a live session.

**Non-Goals:**
- Building a generalized filesystem search engine (discovery is strictly scoped to the current media directory).
- Extensive validation of URL content beyond basic protocol verification.

## Decisions

- **State Management**: Introduce `SOURCE_URL_CACHE`, `SOURCE_URL_FILE_PATH`, and `LAST_PATH_FOR_URL` as local state variables in `lls_core.lua`.
- **Validation-on-Demand**: Before returning from the cache, the system must verify that the `SOURCE_URL_FILE_PATH` still exists. If the file is missing (indicating a rename or deletion), the cache is invalidated.
- **Protocol-First Parsing**: Use Lua pattern matching (`^[Uu][Rr][Ll]%s*=%s*(https?://%S+)`) to extract URLs from files, supporting the standard `.url` INI structure and simple text assignments.
- **Periodic Sync Integration**: Add an explicit discovery call to the `anki_sync_period` timer loop. This ensures that even if a user adds a `.url` file *after* a media file is opened, the URL will be available for export without a restart.

## Risks / Trade-offs

- **File I/O Overhead**: Periodic scanning and file opening could theoretically impact performance. This is mitigated by restricting scans to a 30-second window (default) and using localized path verification before full directory re-reads.
