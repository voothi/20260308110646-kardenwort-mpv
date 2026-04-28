## Why

The current logic for generating phrase strings (SentenceSource) in paired highlighting mode D creates incorrect formatting. When a non-contiguous phrase is captured (e.g., words separated by other text), the generated string does not include the full captured phrase with proper pink highlighting, and erroneously appends an ellipsis (`...`) at the end of the phrase, which is confusing and degrades the quality of Anki exports.

## What Changes

- Modify the phrase generation logic to accurately capture and format the full text span for split selections in mode D.
- Remove the erroneous trailing ellipsis that currently appears at the end of split-phrase strings.
- Ensure the exported text reflects the exact sequence of selected words with appropriate ` ... ` spacing between separated components.

## Capabilities

### New Capabilities

### Modified Capabilities
- `tsv-export-formatting`: The requirement for extracting non-contiguous phrases is changing to ensure proper ellipsis insertion between the selected words without appending trailing ellipses.

## Impact

- `lls_core.lua` (specifically the phrase extraction and Anki context preparation functions).
- The resulting TSV data generated for Anki mining.
