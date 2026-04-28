## 1. Code Change

- [x] 1.1 In `dw_anki_export_selection` (lls_core.lua ~L3603), modify the early-break condition on the final subtitle line: change `if is_last_line and t.logical_idx > p2_w + L_EPSILON then break end` so that it only breaks when `t.is_word == true`. Non-word (punctuation/space) tokens with fractional indices after `p2_w` shall fall through to the existing inclusion logic.
- [x] 1.2 Verify that the changed condition does NOT affect middle lines (`is_last_line == false`), which must behave identically to before.
- [x] 1.3 Verify that the single-word export path (`elseif cl ~= -1` branch, ~L3679) is untouched.

## 2. Validation

- [ ] 2.1 Test with subtitle `[UMGEBUNG] Sport-Thieme (Gersdorf/Straubing-Ost)` as the final line of a selection — confirm the exported phrase includes the closing `)`.
- [ ] 2.2 Test a multi-line selection whose final line ends with a period (e.g. `...Versandbereich.`) — confirm `.` is preserved.
- [ ] 2.3 Test a selection that does NOT end with trailing punctuation (final word is the last character) — confirm no regression.
- [ ] 2.4 Test a single-word MMB export — confirm no change in behavior.
- [ ] 2.5 Test a paired-mode (Ctrl/pink) export — confirm `ctrl_commit_set` path is unaffected.
- [x] 2.6 Confirm the `WordSourceIndices` index string is unchanged (trailing punctuation tokens are not word tokens and should not appear in the index).
