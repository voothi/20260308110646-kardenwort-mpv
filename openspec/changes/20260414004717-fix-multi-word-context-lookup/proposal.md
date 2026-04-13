## Why

When committing a Ctrl+LMB/Ctrl+MMB multi-word selection, the exported Anki context is wrong: `extract_anki_context` receives a context window anchored on the MMB-clicked line, but the composed term (built from non-contiguous picks across multiple lines) may not appear verbatim in that narrow window, causing the function's substring search to miss and return unrelated surrounding text instead.

## What Changes

- **Fix `ctrl_commit_set`**: Build the context window spanning from the **earliest** selected word's line to the **latest** selected word's line (instead of only around the MMB-commit line), so the full composed term always falls inside the context passed to `extract_anki_context`.
- **Use `time_pos` of the earliest member line** (document-order first) for consistent timestamp anchoring, since that is the natural "start" of the selection.
- **No changes to `extract_anki_context`**: The existing logic is correct once the input context window reliably contains the term.

## Capabilities

### New Capabilities
- *(none)*

### Modified Capabilities
- `ctrl-multiselect`: The commit handler's context-gathering logic changes so the window spans all selected lines rather than only the MMB-clicked line.

## Impact

- **`scripts/lls_core.lua`** — `ctrl_commit_set` function (lines ~1958–1971): replace single-line-anchored context window with a span from `members[1].line` to `members[#members].line`.
- No spec-level requirement changes; this is a bug fix in the existing Ctrl+MMB commit flow.
- No changes to configuration, dependencies, or other modules.
