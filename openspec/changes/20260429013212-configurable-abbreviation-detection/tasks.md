## 1. Options Table Update

- [x] 1.1 Add `anki_abbrev_list = "ca. z.B. usw. bzw. etc. t.con"` to `Options` table in `lls_core.lua` (near line 225)
- [x] 1.2 Add `anki_abbrev_smart = true` to `Options` table in `lls_core.lua`

## 2. Refactor `is_abbrev` Helper

- [x] 2.1 Update `is_abbrev(w)` in `lls_core.lua`:
  - [x] Add check against `Options.anki_abbrev_list` (case-insensitive)
  - [x] Wrap existing heuristic checks with `if Options.anki_abbrev_smart then ... end`

## 3. Configuration Files Synchronization

- [x] 3.1 Update `mpv.conf`: add `lls-anki_abbrev_list` and `lls-anki_abbrev_smart` with descriptions
- [x] 3.2 Update `lls.conf`: add the new parameters with default values
