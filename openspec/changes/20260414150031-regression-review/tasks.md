# Tasks: Regression Review & Stability Validation

## 1. Static Code Analysis (Phase 2 Review)

- [ ] 1.1 Review `load_anki_tsv` for potential logic loops during file creation failures.
- [ ] 1.2 Verify `term_header_name` filtering logic against various `anki_mapping.ini` configurations.
- [ ] 1.3 Audit `cmd_toggle_drum_window` to ensure `FSM` state is preserved or rolled back on `pcall` failure.
- [ ] 1.4 Check `update_font_scale` and `update_media_state` observers for performance impact of added error handling.

## 2. Requirement Verification

- [ ] 2.1 Verify that the "auto-creation" requirement doesn't conflict with users who want to manage TSVs manually.
- [ ] 2.2 Confirm that "header filtering" correctly handles localized or custom header names.
- [ ] 2.3 Ensure "Initialization Print" statements are sufficient for debugging without flooding the mpv console.

## 3. Artifact Finalization

- [ ] 3.1 Summarize findings in a `regression-report.md` (to be created in Phase 2).
- [ ] 3.2 Archive the change if no critical issues are found.
