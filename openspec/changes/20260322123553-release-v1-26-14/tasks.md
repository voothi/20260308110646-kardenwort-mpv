# Tasks: BOM-Aware Subtitle Parsing

## 1. Parser Refinement
- [x] Identify UTF-8 BOM interference in `.srt` files
- [x] Update `clean_text_srt()` to strip BOM sequence (`\xEF\xBB\xBF`)
- [x] Verify correct identification of subtitle index `1` in BOM files

## 2. Validation
- [x] Test with BOM-encoded `.srt` files
- [x] Test with non-BOM `.srt` files to ensure compatibility
- [x] Confirm no regressions in standard subtitle display logic
