# Proposal: Fix Non-Contiguous Context Export

## Problem

When exporting non-contiguous selections (pink highlights/paired selections, e.g., separable verbs like "pick ... on") to Anki, the `SentenceSource` (context) field in the TSV often fails to include the full captured phrase and ends with a confusing, unwanted ellipsis. 

This occurs because the `extract_anki_context` engine in `lls_core.lua` assumes keywords are contiguous when validating sentence word counts. If a sentence is long (> 40 words) and the engine cannot find the "pick ... on" phrase as a single contiguous sequence of tokens, it hits a hardcoded fallback that truncates the sentence to the first 100 characters and appends `...`. This frequently cuts off the second part of the phrase if it appears further in the subtitle line.

## What Changes

- **Robust Context Anchoring**: Refactor `extract_anki_context` to handle non-contiguous word sets when calculating the truncation "center."
- **Eliminate Dumb Truncation**: Remove the hardcoded 100-character `sub(1, 100) .. "..."` fallback in favor of a pivot-aware extraction that prioritizes keeping all selected words in the viewport.
- **Smart Word Search**: Update the word-search logic to ignore the literal `...` joiner used in composed terms, preventing accidental anchoring to ellipses in the source text.

## Capabilities

### New Capabilities
- None

### Modified Capabilities
- `anki-export-mapping`: Update requirements for `SentenceSource` generation to explicitly support non-contiguous grounding and pivot-aware truncation.

## Impact

- **Affected Code**: `scripts/lls_core.lua` (specifically `extract_anki_context` and its invocation in `ctrl_commit_set`).
- **TSV Quality**: Significant improvement in context quality for split-phrase mining, ensuring the "full sentence" requirement is met even for long lines.
