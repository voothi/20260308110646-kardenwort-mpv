## Verification Notes (2026-05-11)

### Nuances captured in docs/specs
- Contract and terminology captured in:
  - `openspec/changes/20260511001834-formalize-autopause-transit-contract/playback-mechanism-review-20260511.md`
  - `openspec/changes/20260511001834-formalize-autopause-transit-contract/change-request-interface.md`
- Requirement-level behavior captured in change specs:
  - `specs/immersion-engine/spec.md` (inside-card vs cross-card transit)
  - `specs/karaoke-autopause/spec.md` (suppression only for cross-card transit)
  - `specs/fsm-architecture/spec.md` (deterministic inhibit lifecycle + stale-state hygiene)
  - `specs/playback-change-interface/spec.md` (single-action contract)

### Code coverage alignment
- Implemented split transit state in `scripts/lls_core.lua`:
  - `TIMESEEK_INHIBIT_UNTIL` (legacy sentinel retained)
  - `REWIND_TRANSIT_CROSS_CARD` (new suppression classifier)
  - `REWIND_START_IDX` (inside-card discrimination)
- Gating points aligned:
  - `cmd_seek_time` sentinel/set/accumulate and cross-card classifier
  - `tick_autopause` suppression gate
  - `master_tick` PHRASE jerk-back gate and deterministic clear
  - replay/manual navigation stale-state resets

### Tests
- User-confirmed focused runtime tests:
  - `test_backward_seek_activates_inhibit` PASSED
  - `test_backward_seek_records_pre_seek_position` PASSED
  - `test_multiple_backward_seeks_keep_max_inhibit` PASSED
- Local structural validation:
  - `python -m pytest -q tests/acceptance/test_20260509134903_timeseek_transit.py::TestTimseekTransitStructural`
  - Result: `15 passed`
- Added structural assertions for new nuance:
  - state snapshot includes `rewind_transit_cross_card`
  - `REWIND_TRANSIT_CROSS_CARD` declared in FSM
  - cross-card gate present in `tick_autopause`
  - cross-card gate present in `get_effective_boundaries`
  - Autopause ON + PHRASE + `Space` hold override is present in `get_effective_boundaries`
  - PHRASE jerk-back gate disables while the `Space` hold override is active

### Space-hold PHRASE nuance (new)
- Implemented temporary MOVIE-like handover while `Space` is held in `Autopause ON + PHRASE`.
- Release semantics remain edge-triggered by `cmd_smart_space` key-up; implicit key-up events from mpv/hardware multi-key behavior are treated as release and normal PHRASE autopause resumes at the next boundary.
- Refined guard: the override now activates only after the hold exceeds `space_tap_delay`, so quick taps do not accidentally switch PHRASE into MOVIE-like progression.

### Test execution (this session)
- `python -m pytest -q tests/acceptance/test_20260509134903_timeseek_transit.py -k Structural`
- Result: `17 passed`
- Full mpv-backed run attempted but blocked in this environment (`TimeoutError: mpv IPC not ready`, Windows pipe access `OSError: 5`), so runtime acceptance remains pending local replay.

### Remaining validation item
- Full non-regression boundary sweep (`tasks.md` item 4.2) remains open until broader acceptance set is re-run with working mpv IPC access.
