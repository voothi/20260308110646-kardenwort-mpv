## Why

The current metadata filtering logic (stripping `[...]` tags) is too aggressive, preventing users from adding terms that are enclosed in brackets (e.g., `[UMGEBUNG]`) and breaking highlighting for words near such tags due to strict context mismatch. This makes it impossible to save certain vocabulary items and causes visual regressions in highlight persistence for surrounding words.

## What Changes

- Modify `term` export logic to allow bracketed expressions if they represent the entire selection (stripping brackets but keeping content).
- Modify `calculate_highlight_stack` to treat bracketed metadata tags as "safe" neighbors during strict context matching, preventing highlight loss for words adjacent to tags.
- Ensure consistent metadata stripping across single-click (MMB) and multi-click (Ctrl+MMB) export handlers.

## Capabilities

### New Capabilities
- None

### Modified Capabilities
- `metadata-tag-filtering`: Update requirements to allow selective preservation of bracketed content when it is the primary export target.
- `high-recall-highlighting`: Update requirements to explicitly handle metadata tags in the "neighborhood" scan during context verification.

## Impact

- `lls_core.lua`: `dw_anki_export_selection`, `ctrl_commit_set`, and `calculate_highlight_stack` will be modified.
- Anki Export: Users will now be able to save terms like `[UMGEBUNG]` (saved as `UMGEBUNG`).
- Subtitle Rendering: Highlights will correctly persist for words adjacent to `[...]` tags.
