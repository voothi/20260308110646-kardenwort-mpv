## 1. Interface Synchronization

- [ ] 1.1 Update `extract_anki_context` signature to replace `pivot_pos` with `coord_map`.
- [ ] 1.2 Update the call site in `dw_anki_export_selection` to pass `advanced_index`.
- [ ] 1.3 Ensure the single-word export path also passes the correctly formatted `0:W:1` index string.

## 2. Logical Pivot Parsing

- [ ] 2.1 Implement a helper to parse the first `LineOffset:WordIndex:TermPos` from the coordinate map string.
- [ ] 2.2 Add logical-to-byte offset mapping logic within the context search loop for current candidates.

## 3. Hardened Marker Search

- [ ] 3.1 Update the `extract_anki_context` search loop to prioritize logical index verification if `coord_map` is present.
- [ ] 3.2 Implement `+/- 1` segment drift tolerance when resolving the origin line relative to the current context line.
- [ ] 3.3 Preserve geometric midpoint calculation as a conditional fallback for legacy records.

## 4. Verification & Regression

- [ ] 4.1 Test "Scene-Locked" extraction on segments with identical term repetition.
- [ ] 4.2 Verify that multi-sub-segment selections still correctly bridge and anchor via the Multi-Pivot map.
- [ ] 4.3 Confirm total compatibility with legacy `.tsv` records missing logical grounding.
