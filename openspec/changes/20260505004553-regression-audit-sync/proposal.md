# Proposal: Regression Audit and Synchronization (ZID: 20260505004553)

## Objective
Restore 100% compliance with OpenSpec core specifications and historical baselines by addressing regressions and implementation gaps identified in the v1.58.50 audit.

## Motivation
The current codebase (`04eff08`) exhibits critical deviations from the `tsv-state-recovery` specification, specifically regarding error handling and dynamic header detection. Furthermore, the ingestion engine lacks robustness against malformed SRT whitespace, and the internal branding has desynchronized from the canonical historicity ledger.

## What Changes
- **Hardening**: The TSV parsing loop in `load_anki_tsv` will be wrapped in a `pcall` to ensure system stability against malformed record files.
- **Dynamic Identification**: Hardcoded header guards in the Anki loader will be replaced with dynamic comparison against configured field names.
- **Robustness**: The `clean_text_srt` utility will be updated with mandatory whitespace trimming to prevent "phantom" subtitle blocks.
- **Branding Sync**: The project header in `lls_core.lua` will be updated to the canonical "Language Acquisition Suite".

## Capabilities

### New Capabilities
- None

### Modified Capabilities
- `tsv-state-recovery`: Hardening the implementation to satisfy REQ-9 (pcall guard) and dynamic header exclusion.
- `project-terminology-and-historicity`: Synchronizing file-level branding with the established canonical thesaurus.

## Impact
- **lls_core.lua**: Core logic modifications to `load_anki_tsv`, `clean_text_srt`, and file metadata.
- **Stability**: Improved resilience during background synchronization of mining records.
- **Ingestion**: Enhanced compatibility with varying SRT line-ending and whitespace styles.
