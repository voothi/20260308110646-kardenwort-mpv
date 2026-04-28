## Context

In paired highlighting mode D, users can select non-contiguous phrases for Anki export. The current implementation correctly handles some aspects of spacing, but it incorrectly constructs the final phrase string. It fails to capture the full selected span properly and mistakenly appends a trailing ellipsis (`...`) to the extracted phrase. This is visible in the TSV where entries like "pick ... on" appear incorrectly with an ellipsis at the end of the sentence or phrase segment.

## Goals / Non-Goals

**Goals:**
- Fix the logic for SentenceSource phrase extraction for paired highlights in Mode D so that split phrases include the exact literal text matching the selected words with proper intervening ` ... ` gaps.
- Remove the trailing ellipsis from the end of generated phrases.

**Non-Goals:**
- Changes to single-word selection behavior.
- Alterations to UI highlight drawing or hit-zone calculations, only the text extraction logic for TSV generation.

## Decisions

- **Refactor phrase reconstruction logic:** Instead of a complex, buggy substring matching that over-truncates and appends ellipses unconditionally at the boundary of a selected span, we will track the bounds of the selected tokens exactly, inserting ` ... ` only *between* non-contiguous active tokens. If a token is the last selected token, no trailing ellipsis should be added.

## Risks / Trade-offs

- **Risk**: Modifying the TSV extraction logic could inadvertently break other export fields if not isolated.
- **Mitigation**: Changes will be strictly contained to the function that constructs the split phrase strings for Anki (such as the context extraction or the loop that builds the phrase).
