# Proposal: BOM-Aware Subtitle Parsing (v1.26.14)

## Problem
The custom subtitle parser in `lls_core.lua` failed to recognize the first subtitle block in `.srt` files encoded with a UTF-8 Byte Order Mark (BOM). This caused the first line of dialogue to be skipped in Drum Mode.

## Proposed Change
Update the subtitle cleaning logic to proactively detect and strip the UTF-8 BOM sequence from input lines before attempting to match subtitle block identifiers.

## Objectives
- Ensure all subtitle blocks, including the first one, are correctly parsed in BOM-encoded files.
- Maintain compatibility with non-BOM files and standard UTF-8 encoding.
- Improve the robustness of the custom `.srt` parser.

## Key Features
- **BOM Stripping**: Proactive removal of `\xEF\xBB\xBF` sequence in `clean_text_srt()`.
- **Parser Resilience**: Robust identification of subtitle IDs (`^%d+$`) regardless of file encoding artifacts.
