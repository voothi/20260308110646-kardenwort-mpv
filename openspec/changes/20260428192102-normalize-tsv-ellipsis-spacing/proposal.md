## Why

The TSV export formatting for Anki mining had become overcomplicated through the use of a unified "smart joiner" function (`compose_term_smart`) that applied aggressive punctuation rules and regex-based space normalization. This led to regressions where desired spaces before ellipses were stripped and original subtitle spacing was lost. Reverting to a literal, token-based concatenation ensures predictable results and honors the source text's original formatting.

## What Changes

- **Literal Term Construction**: Revert `source_word` composition to use manual string concatenation instead of the `compose_term_smart` service.
- **Fixed Ellipsis Padding**: Mandate the use of a hardcoded, space-padded ` ... ` string for logical gaps in selection.
- **Original Space Preservation**: Utilize `build_word_list_internal(..., true)` to capture and preserve all original spaces and punctuation between selected words directly from the subtitle stream.
- **Regex Filter Removal**: Remove global space-collapsing regex filters (`gsub("%s+", " ")`) from the mining path to prevent unintended text alteration.

## Capabilities

### New Capabilities
- `tsv-export-formatting`: Formalizes the requirements for literal, space-preserving term reconstruction in Anki exports.

### Modified Capabilities
- `smart-joiner-service`: Clarify that this service is intended for UI/OSD display only and should NOT be used for mining data where literal accuracy is paramount.

## Impact

- **Affected Code**: `scripts/lls_core.lua` (mining loop logic).
- **TSV Data**: More consistent and "honest" representation of selected phrases in Anki.
- **UI**: No impact on OSD rendering, which continues to use the smart joiner.
