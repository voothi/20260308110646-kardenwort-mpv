## Why

When users save a sentence to their favorites that starts with a capital letter and follows a period or the start of a block in the source text, it often lacks a trailing period in the exported result. This results in grammatically incomplete flashcards. Automating this punctuation ensures exported sentences are clean and ready for study.

## What Changes

- Implement detection logic in the Anki export flow to identify sentences that follow a period (or block start) and start with a capital letter.
- Automatically append a period to such sentences if they do not already end with terminal punctuation (., !, ?).

## Capabilities

### New Capabilities
- `sentence-punctuation-normalization`: Ensures grammatically correct terminal punctuation for extracted sentences based on their contextual position.

### Modified Capabilities
- None

## Impact

- `scripts/lls_core.lua`: Modification of the text extraction/export logic for favorites.
