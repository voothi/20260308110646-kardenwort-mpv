# Tasks: Fixing TSV Deletion and Drum Window Hang

## 1. Startup Resilience
- [ ] 1.1 Wrap the top-level `update_media_state()` call in `mp.observe_property` and script init with a `pcall`.
- [ ] 1.2 Add defensive logging to identify if/when the init logic fails.

## 2. Robust TSV Parsing
- [ ] 2.1 Refactor `load_anki_tsv` to clear `FSM.ANKI_HIGHLIGHTS` when `io.open` fails.
- [ ] 2.2 Implement dynamic header skipping by looking up `config.fields[term_col]`.
- [ ] 2.3 Wrap the internal file parsing loop in a `pcall`.

## 3. Drum Window Safety
- [ ] 3.1 Use `load_anki_tsv(true)` at the start of `cmd_toggle_drum_window`.
- [ ] 3.2 Add a `#subs == 0` guard to `cmd_toggle_drum_window` with OSD feedback.

## 4. Verification
- [ ] 4.1 Test script loading with no TSV file present.
- [ ] 4.2 Test mid-session TSV deletion (Verify highlights disappear after 5s or on next DW open).
- [ ] 4.3 Test "blank" subtitle file (Verify DW shows an error message instead of a blank UI).
