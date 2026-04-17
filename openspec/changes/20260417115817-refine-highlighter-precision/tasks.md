## 1. Core Script Updates

- [x] 1.1 Update `Options.anki_local_fuzzy_window` from `10.0` to `3.0` in `scripts/lls_core.lua`.
- [x] 1.2 Update `Options.anki_context_strict` from `false` to `true` in `scripts/lls_core.lua`.

## 2. Global Configuration Updates

- [x] 2.1 Update `lls-anki_local_fuzzy_window` to `3.0` in `mpv.conf` (overriding the existing restricted value of `1`).
- [x] 2.2 Update `lls-anki_context_strict` to `yes` in `mpv.conf`.

## 3. Verification

- [ ] 3.1 Restart mpv and verify that "phantom" highlights for common words (like `die`) no longer appear in unrelated subtitle lines.
- [ ] 3.2 Confirm that phrase-based highlights (e.g. `41 bis 45`) remain functional when the current subtitle contains the relevant context.
