## Why

Two related bugs cause incorrect Anki context when committing a Ctrl+LMB/Ctrl+MMB multi-word selection:

1. **Wrong context window anchor** — `ctrl_commit_set` gathered context lines around the single MMB-clicked line. When words are picked from multiple subtitle lines, the context window may not overlap all contributing lines, so the composed term can't be located within it.

2. **Non-contiguous term search failure** — Even with the correct window, `extract_anki_context` tries to find the composed term as a verbatim substring (e.g. `"ist die Anwohner"`). But a non-contiguous selection skips words in between (actual text: `"ist für die Anwohner"`), so the search always fails for such terms, and the function falls back to returning the raw full-blob context — which is entirely wrong.

## What Changes

- **Fix `ctrl_commit_set`**: Build the context window spanning from the **earliest** selected word's line to the **latest** selected word's line (instead of only around the MMB-commit line), so all contributing lines are always included.
- **Use `time_pos` of the earliest member line** (document-order first) for consistent timestamp anchoring, since that is the natural "start" of the selection.
- **Fix `extract_anki_context`**: Implement a center-proximity search — when the composed term can't be found verbatim (non-contiguous picks), the system searches for every word of the term and anchors on the occurrence closest to the center of the context blob. This reliably handles common words (like "und") appearing multiple times in the padding.

## Capabilities

### New Capabilities
- *(none)*

### Modified Capabilities
- `ctrl-multiselect`: The commit handler's context-gathering logic changes so the window spans all selected lines rather than only the MMB-clicked line.
- `adaptive-context-truncation`: `extract_anki_context` gains a center-proximity search fallback for non-contiguous terms that cannot be found verbatim.

## Impact

- **`scripts/lls_core.lua`** — `ctrl_commit_set` (~line 1958): replace single-line-anchored context window with span from `members[1].line` to `members[#members].line`.
- **`scripts/lls_core.lua`** — `extract_anki_context` (~line 737): Add center-proximity multi-word search fallback when verbatim term search returns nil.
- No changes to configuration, dependencies, or other modules.
