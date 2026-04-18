## 1. Highlighting Engine Logic

- [ ] 1.1 Update `calculate_highlight_stack` in `lls_core.lua` to identify elliptical terms (containing the exact string ` ... `).
- [ ] 1.2 Implement the "Orange Bypass": If a term contains a space-padded ellipsis, skip Phase 1 (Contiguous) and Phase 2 (Contextual) matching for that term.
- [ ] 1.3 Ensure that terms with ellipses still correctly trigger Phase 3 (Split) matching by ensuring the `...` doesn't break the word-stripping logic prematurely.

## 2. Selection and Export Logic

- [ ] 2.1 Refactor `ctrl_commit_set` in `lls_core.lua` to detect gaps between non-contiguous selected words.
- [ ] 2.2 In `ctrl_commit_set`, iterate through sorted selection members and inject the space-padded ellipsis ` ... ` joiner wherever a line gap occurs OR a `logical_idx` gap > 1 exists within the same line.
- [ ] 2.3 Verify `dw_anki_export_selection` (range drag) remains unaffected, as it inherently defines a contiguous sequence.

## 3. Verification and Polish

- [ ] 3.1 Test Case: Select "Sie" and "Hören" in a split context using Ctrl+Click. Verify the exported term in the TSV is exactly `Sie ... Hören`.
- [ ] 3.2 Test Case: Verify `Sie ... Hören` in the TSV highlights split instances in purple but ignores contiguous `Sie hören` (leaves them white or colors them orange only if a separate contiguous record exists).
- [ ] 3.3 Test Case: Verify standard contiguous selections (DRAG or single/multi-word adjacent Ctrl+Click) still export without ellipses.
