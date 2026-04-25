## 1. Core Logic Refinement

- [x] 1.1 Implement smart focus fallback in `cmd_dw_copy` to prioritize navigated lines in Book Mode.
- [x] 1.2 Implement robust context splicing for verbatim selections within the `COPY_CONTEXT` block.
- [x] 1.3 Remove aggressive punctuation and bracket stripping from the final clipboard cleanup.

## 2. Verification

- [x] 2.1 Verify navigation copy in Book Mode (White highlight priority).
- [x] 2.2 Verify verbatim context wrapping (Specific word focus within context lines).
- [x] 2.3 Verify bracket preservation (No stripping of `[...]` markers).
