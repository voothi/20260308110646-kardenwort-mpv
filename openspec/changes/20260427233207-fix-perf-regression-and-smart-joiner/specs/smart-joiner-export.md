# Spec: Smart Joiner TSV Export Integration

## Context
TSV exports for Anki cards currently assemble multi-word terms using simple spaces. This violates the visual parity expected when exporting terms that contain smart punctuation (e.g. hyphenated words or punctuation marks).

## Requirements
- **Integration**: The `dw_anki_export_selection` and `ctrl_commit_set` functions MUST use the `compose_term_smart` service to construct the final exported `term` string.
- **Accuracy**: The exported term MUST precisely reflect the smart spacing rules defined in the `compose_term_smart` service (e.g., "Marken-Discount", not "Marken -Discount").

## Verification
- Select "Marken-Discount" via click-and-drag.
- Export to Anki.
- Verify the TSV file contains "Marken-Discount" without any spaces surrounding the hyphen.
