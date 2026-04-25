# Design: BOM-Aware Subtitle Parsing

## System Architecture
The change is localized within the subtitle parsing pipeline in `lls_core.lua`.

### Components
1.  **Subtitle Cleaner (`clean_text_srt`)**:
    - A helper function that sanitizes raw lines from `.srt` files.
    - Updated to check for the BOM sequence at the very beginning of the string.
2.  **Parser Logic**:
    - The main parsing loop continues to use `^%d+$` to find subtitle indexes.
    - Since `clean_text_srt` is called before this check, the index `1` is now correctly identified even if preceded by a BOM.

## Implementation Strategy
- **Regex/Pattern Match**: Use a string substitution to remove the 3-byte sequence `\xEF\xBB\xBF`.
- **Edge Case Handling**: Ensure the stripping only occurs at the start of the file/line to avoid accidental data loss.
- **Verification**: Test with both BOM and non-BOM encoded files to ensure no regressions.
