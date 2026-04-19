## 1. Highlighting Engine

- [x] 1.1 Update `calculate_highlight_stack` to include a safeguard against fuzzy fallback when grounding is available.
- [x] 1.2 Implement the `(Options.anki_global_highlight or not (data.__pivots and #data.__pivots > 0))` condition at line 994.

## 2. Export Logic

- [x] 2.1 Update single-word click handler (around line 2896) to generate `advanced_index` using `string.format("0:%d:1", cw)`.
- [x] 2.2 Verify that `advanced_index` is correctly propagated through `save_anki_tsv_row` to the `FSM.ANKI_HIGHLIGHTS` table.

## 3. Validation

- [x] 3.1 Verify that clicking the second instance of a word in a sentence only highlights that instance.
- [x] 3.2 Verify that legacy cards (without indices) still highlight using fuzzy context.
