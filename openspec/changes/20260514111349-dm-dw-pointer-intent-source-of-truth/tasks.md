## 1. Intent Snapshot Foundation

- [x] 1.1 Add a DW/DM navigation-intent snapshot resolver in `scripts/kardenwort/main.lua` with explicit active-context fallback order.
- [x] 1.2 Refactor `cmd_dw_line_move` and `cmd_dw_word_move` to consume one immutable snapshot per navigation intent.
- [x] 1.3 Ensure intent snapshot usage is shared by both DW (`W`) and DM mini (`C` with `W` closed) pointer paths.

## 2. Event Gating and Rebase Logic

- [x] 2.1 Update arrow key binding plumbing to pass event metadata consistently for EN and RU arrow bindings.
- [x] 2.2 Implement event-type gating (`down/repeat/up`) so null-pointer activation consumes one deterministic entry step without timing guards.
- [x] 2.3 Implement deterministic desync-rebase behavior (manual pointer off active line -> rebase -> continue same intent without Shift).

## 3. Acceptance and Regression Coverage

- [x] 3.1 Extend `tests/acceptance/test_20260514001942_dm_dw_state_edges.py` with runtime boundary-tick activation tests (AUTOPAUSE OFF, MOVIE path).
- [x] 3.2 Add runtime checks that EN and RU arrow bindings follow identical activation semantics.
- [x] 3.3 Preserve or adapt structural tests only as support checks, while making runtime checks mandatory for this change's sign-off.

## 4. Spec Alignment and Validation

- [x] 4.1 Update base specs in `openspec/specs/` to reflect the new intent-snapshot and boundary-runtime contracts.
- [ ] 4.2 Run targeted acceptance tests for DM/DW state edges, then run full regression suite and capture results in `docs/conversation.log`.
- [ ] 4.3 Perform final behavioral verification against the reported user flow (live playback boundary activation and `UP -> Esc -> UP` recovery equivalence).
