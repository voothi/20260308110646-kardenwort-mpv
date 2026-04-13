## Why

When users save a sentence to their favorites that starts with a capital letter and originally ends with terminal punctuation in the source text, the export cleaning process currently strips that punctuation from the `source_word` field. This results in grammatically incomplete flashcards for full-sentence exports. Restoring this punctuation ensures exported sentences are clean and professionally formatted.

## What Changes

- Implement detection logic in the term cleanup flow to identify if a `term` originally ended with terminal punctuation.
- Automatically restore a period to the `source_word` field if the term starts with a capital letter and had original terminal punctuation but lost it during the standard punctuation stripping phase.

## Capabilities

### New Capabilities
- `sentence-punctuation-normalization`: Ensures grammatically correct terminal punctuation for extracted terms and context sentences based on their original source state.

### Modified Capabilities
- None

## Impact

- `scripts/lls_core.lua`: Modification of the text extraction/export logic for favorites.
