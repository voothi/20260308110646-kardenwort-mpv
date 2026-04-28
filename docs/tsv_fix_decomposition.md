# Walkthrough: TSV Ellipsis and Spacing Fix

This change fixes the spacing issues in TSV exports, specifically ensuring that ellipses are correctly padded and that original text spacing is not doubled.

## 1. Enhancing the Smart Joiner
In `scripts/lls_core.lua`, the `compose_term_smart` function was adding a space between any two tokens unless they were specific punctuation. We updated it to also skip adding a space if either token already has whitespace at the boundary.

**Change:**
```lua
-- Before
if no_space_before or no_space_after then

-- After
if no_space_before or no_space_after or w:match("%s$") or next_w:match("^%s") then
```

## 2. Updating the Ellipsis Token
The non-contiguous selection logic was using a raw `...` string. This was updated to use a space-padded version `" ... "`.

**Change:**
```lua
-- Before
table.insert(term_tokens, "...")

-- After
table.insert(term_tokens, " ... ")
```

## 3. Specification Updates
The following specifications were updated to make these rules "strict" and described in words:
- `openspec/specs/smart-joiner-service/spec.md`: Added "Whitespace Awareness" rule and clarified the ` ... ` separator.
- `openspec/specs/anki-export-mapping/spec.md`: Explicitly mandated the space-padded delimiter for paired selections.

## Verification Checklist
1. Export a non-contiguous pair (e.g., `she's` and `putting`). Result should be `she's ... putting`.
2. Export a phrase with multiple spaces in the source (e.g., `find   those`). Result should be `find   those`, not `find    those` (4 spaces).
3. Ensure hyphens still join without spaces (e.g., `Marken-Discount`).
