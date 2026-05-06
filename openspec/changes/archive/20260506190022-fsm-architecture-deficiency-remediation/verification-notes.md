## Verification Notes

Date: 2026-05-06
Change: `20260506190022-fsm-architecture-deficiency-remediation`

### Scope Covered

- ASS gatekeeping transition safety (`FSM.DRUM` + `FSM.DRUM_WINDOW` forced OFF in ASS context).
- Search modal lifecycle symmetry for forced character bindings, including German characters.
- Esc staged contract alignment (Pink -> Range -> Pointer, no implicit close in `cmd_dw_esc` path).

### Evidence

1. Static code validation
- Confirmed ASS gatekeeping block now forces both modes OFF and restores native visibility/position state.
- Confirmed canonical shared search character list drives both bind and unbind paths.
- Confirmed German whitelist (`ä`, `ö`, `ü`, `ß`, `Ä`, `Ö`, `Ü`, `ẞ`) is explicitly enforced via runtime guard.
- Confirmed Esc contract comments now match implemented staged behavior.

2. Syntax validation
- Ran Lua parse check:
  - `lua -e "assert(loadfile('scripts/lls_core.lua')); print('lua-parse-ok')"`
  - Result: `lua-parse-ok`

3. Targeted grep checks
- Located expected symbols and messages:
  - `SEARCH_INPUT_CHARS`, `SEARCH_GERMAN_CHARS`, `verify_search_german_whitelist`
  - `SEARCH_CHAR_BINDINGS` lifecycle usage
  - ASS gatekeeping message: `Custom OSD: AUTO-DISABLED (ASS Track Loaded)`
  - Esc contract marker: `No implicit window close occurs in cmd_dw_esc itself.`

### Residual Risks

- ASS gatekeeping now force-closes Drum Window in ASS contexts; this is intentional per remediation spec but may feel stricter for users who previously relied on partial mixed-mode behavior.
- Search cleanup relies on mpv key binding removal semantics; defensive sweep and canonical list reduce leak risk, but runtime behavior should still be observed in real interaction sessions.

