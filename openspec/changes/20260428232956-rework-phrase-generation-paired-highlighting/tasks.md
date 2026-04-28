## 1. Analysis and Setup

- [ ] 1.1 Locate the phrase extraction logic for TSV generation in `lls_core.lua` (likely `extract_anki_context` or similar).
- [ ] 1.2 Analyze how selected spans are currently captured and converted into the `source_word` string.

## 2. Refactoring Phrase Logic

- [ ] 2.1 Refactor the `source_word` string building loop to iterate precisely over selected active tokens and capture their literal text.
- [ ] 2.2 Implement logic to detect gaps between non-contiguous selected tokens and correctly insert the ` ... ` marker only between them.
- [ ] 2.3 Ensure the gap insertion logic explicitly excludes adding a trailing ellipsis after the last selected token in the phrase.

## 3. Verification

- [ ] 3.1 Verify that single contiguous selections remain unaffected and retain their literal spacing.
- [ ] 3.2 Verify that non-contiguous selections (e.g., paired highlights in mode D) output properly formatted strings without trailing ellipses.
