## 1. Core Logic Fixes (lls_core.lua)

- [x] 1.1 Update `compose_term_smart` to use anchored regex `^...$` for `no_space_before` rules to prevent multi-character bracketed tags from suppressing spaces. (COMPLETED)
- [x] 1.2 Refactor `extract_anki_context` to use substring extraction from the source string instead of re-composing from word lists, ensuring 100% fidelity of punctuation and spacing in the viewport. (COMPLETED)
- [x] 1.3 Make `compose_term_smart` whitespace-aware to prevent doubling of spaces when joining tokens that already contain spaces. (COMPLETED)

## 2. Verification

- [x] 2.1 Verify that `Paketsortierung. [UMGEBUNG]` context preservation works as expected. (COMPLETED)
- [x] 2.2 Verify that `[UMGEBUNG]` is no longer stuck to the preceding word in the phrase field. (COMPLETED)
