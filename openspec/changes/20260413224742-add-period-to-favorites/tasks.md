## 1. Core Implementation

- [ ] 1.1 Modify `extract_anki_context` in `scripts/lls_core.lua` to identify if an extraction started at a sentence boundary.
- [ ] 1.2 Implement a check for leading uppercase characters in the extracted sentence.
- [ ] 1.3 Implement the automatic period appendage logic, ensuring no duplicate punctuation.

## 2. Verification

- [ ] 2.1 Verify capitalized sentences extracted from larger blocks correctly receive a period.
- [ ] 2.2 Verify lowercase fragments remain untouched.
- [ ] 2.3 Verify sentences that already have periods, exclamation marks, or question marks are not modified.
