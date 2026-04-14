# Spec: TSV State Recovery

## Context

`load_anki_tsv(force)` is defined at line ~1121 of `scripts/lls_core.lua`.
It is called from:
- `update_media_state()` at line 1312 (on track change)
- The 5-second periodic timer at line 3924-3931 (already pcall-wrapped)
- `cmd_toggle_drum_window` (after Task 4 fix)

The TSV path is derived by `get_tsv_path()` (line 1080): it takes the current media path,
strips the extension, and appends `.tsv`. Example:
- Media: `C:\videos\lesson.mp4`
- TSV:   `C:\videos\lesson.tsv`

## Requirements

### R1 — File Presence Check

Every call to `load_anki_tsv` MUST attempt `io.open(tsv_path, "r")`.

If `io.open` returns `nil` (file not found, permission denied, or any OS error):
1. Set `FSM.ANKI_HIGHLIGHTS = {}` (empty table — no highlights)
2. Call `mp.msg.verbose("load_anki_tsv: file not found, cleared: " .. tsv_path)`
3. `return` — do not proceed to parse

**Before this fix:** the function returned without clearing highlights. If a file existed
on the *previous* call and populated `ANKI_HIGHLIGHTS`, those highlights persisted
even after the file was deleted.

### R2 — Dynamic Header Skipping

The TSV file begins with a header row written by `save_anki_tsv_row` when the file is
empty. Example header (from `anki_mapping.ini` with default config):
```
#deck column:5
Quotation	Context	Deck	Source	time	Audio
```

The parsing loop at line 1148 filters lines starting with `#`, so the `#deck` line
is already skipped. But the field-name row (`Quotation\tContext\t...`) is NOT filtered
because the current hardcoded check only excludes `"WordSource"` and `"Term"`.

**Required:** After resolving `term_col` (line ~1142), derive the expected header value:
```lua
local term_header_name = config.fields[term_col]
```
Then use it in the row-filter:
```lua
local is_header = (term == "WordSource" or term == "Term"
                   or (term_header_name and term == term_header_name))
if term and term ~= "" and not is_header then
    -- add to new_highlights
end
```

`config.fields` is the ordered list of field names from `[fields]` section of
`anki_mapping.ini`. `term_col` is the 1-based index of the field mapped to `source_word`.
So `config.fields[term_col]` is the exact string that appears in column 1 of the header row.

### R3 — Empty File Robustness

An empty file (0 bytes) will cause `f:lines()` to immediately return without yielding
any lines. The result is `new_highlights = {}` which is then assigned to `FSM.ANKI_HIGHLIGHTS`.
This is already correct behavior — no special handling needed for 0-byte files beyond R1.

### R4 — Parse Error Isolation

The file-reading loop MUST be wrapped in a `pcall` to prevent a Lua error inside
the loop (e.g. from a malformed multi-byte UTF-8 character in a field value) from
propagating to the calling observer and killing the callback.

Structure:
```lua
local ok, err = pcall(function()
    for line in f:lines() do
        -- ... parse ...
    end
end)
f:close()
if not ok then
    mp.msg.warn("load_anki_tsv: parse error: " .. tostring(err))
    return  -- do NOT assign new_highlights; keep ANKI_HIGHLIGHTS as-is
end
FSM.ANKI_HIGHLIGHTS = new_highlights
```

Note: if parse fails, we keep the previous `ANKI_HIGHLIGHTS` (not cleared), because
the file *exists* but is temporarily unreadable. This is different from R1 (file missing).
