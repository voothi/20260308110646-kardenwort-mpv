# Spec: BOM-Aware Parsing

## Context
Many Windows-based text editors save UTF-8 files with a Byte Order Mark (BOM), which interfered with the strict digit-matching logic of the subtitle parser.

## Requirements
- Identify the UTF-8 BOM sequence (`\xEF\xBB\xBF`).
- Strip this sequence from the beginning of any line before parsing.
- Ensure that subtitle index `1` is correctly identified in BOM-encoded files.

## Verification
- Load a `.srt` file encoded with UTF-8 BOM.
- Verify that the first subtitle line appears correctly in Drum Mode.
- Load a standard UTF-8 file (no BOM) and verify no regression in parsing.
